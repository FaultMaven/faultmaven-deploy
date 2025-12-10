#!/usr/bin/env python3
"""
FaultMaven E2E Smoke Test - Happy Path Validation

This script validates the complete FaultMaven stack by executing a realistic
user journey from health checks through AI-assisted troubleshooting.

Test Flow:
1. Health checks (basic, liveness, readiness)
2. Case creation
3. Evidence upload
4. AI agent query
5. Knowledge base search

Usage:
    python smoke_test.py [--api-url http://localhost:8090]

Exit Codes:
    0 = All tests passed
    1 = One or more tests failed
    2 = Setup/configuration error
"""

import argparse
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
import httpx
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()


class SmokeTestResult:
    """Track test results for final reporting."""

    def __init__(self):
        self.tests: list[tuple[str, bool, Optional[str]]] = []
        self.start_time = datetime.now()

    def add(self, name: str, passed: bool, message: Optional[str] = None):
        """Add test result."""
        self.tests.append((name, passed, message))
        icon = "✅" if passed else "❌"
        status = "[green]PASS[/green]" if passed else "[red]FAIL[/red]"
        msg_text = f" - {message}" if message else ""
        console.print(f"{icon} {name}: {status}{msg_text}")

    def summary(self) -> bool:
        """Print summary and return overall success."""
        duration = (datetime.now() - self.start_time).total_seconds()

        # Create results table
        table = Table(title="Smoke Test Results")
        table.add_column("Test", style="cyan")
        table.add_column("Status", justify="center")
        table.add_column("Details", style="dim")

        for name, passed, message in self.tests:
            status = "[green]✓ PASS[/green]" if passed else "[red]✗ FAIL[/red]"
            details = message or ""
            table.add_row(name, status, details)

        console.print("\n")
        console.print(table)

        # Summary stats
        total = len(self.tests)
        passed = sum(1 for _, p, _ in self.tests if p)
        failed = total - passed

        console.print(f"\n📊 Summary: {passed}/{total} tests passed ({duration:.1f}s)")

        if failed == 0:
            console.print("[bold green]🎉 All tests passed! FaultMaven is operational.[/bold green]")
            return True
        else:
            console.print(f"[bold red]❌ {failed} test(s) failed. Check logs for details.[/bold red]")
            return False


class FaultMavenSmokeTest:
    """E2E smoke test for FaultMaven stack."""

    def __init__(self, api_url: str, timeout: float = 30.0):
        """
        Initialize smoke test.

        Args:
            api_url: API Gateway base URL (e.g., http://localhost:8090)
            timeout: Request timeout in seconds
        """
        self.api_url = api_url.rstrip("/")
        self.timeout = timeout
        self.results = SmokeTestResult()

        # Test data
        self.case_id: Optional[str] = None
        self.evidence_id: Optional[str] = None

    def run(self) -> bool:
        """
        Run complete smoke test suite.

        Returns:
            True if all tests passed, False otherwise
        """
        console.print(f"\n[bold cyan]🚀 FaultMaven E2E Smoke Test[/bold cyan]")
        console.print(f"API URL: {self.api_url}")
        console.print(f"Started: {self.results.start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")

        try:
            # Phase 1: Health checks
            console.print("[bold]Phase 1: Health Checks[/bold]")
            self._test_basic_health()
            self._test_liveness()
            self._test_readiness()

            # Phase 2: Case management
            console.print("\n[bold]Phase 2: Case Management[/bold]")
            self._test_create_case()

            # Phase 3: Evidence upload
            console.print("\n[bold]Phase 3: Evidence Upload[/bold]")
            self._test_upload_evidence()

            # Phase 4: AI agent
            console.print("\n[bold]Phase 4: AI Agent[/bold]")
            self._test_ai_agent_query()

            # Phase 5: Knowledge base
            console.print("\n[bold]Phase 5: Knowledge Base[/bold]")
            self._test_knowledge_search()

            # Final summary
            return self.results.summary()

        except KeyboardInterrupt:
            console.print("\n[yellow]⚠️  Test interrupted by user[/yellow]")
            return False
        except Exception as e:
            console.print(f"\n[red]❌ Unexpected error: {e}[/red]")
            return False

    def _test_basic_health(self):
        """Test basic health endpoint."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(f"{self.api_url}/health")

                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == "healthy":
                        self.results.add("Basic health check", True, f"Gateway v{data.get('version', 'unknown')}")
                    else:
                        self.results.add("Basic health check", False, f"Unexpected status: {data.get('status')}")
                else:
                    self.results.add("Basic health check", False, f"HTTP {response.status_code}")

        except Exception as e:
            self.results.add("Basic health check", False, str(e))

    def _test_liveness(self):
        """Test liveness probe endpoint."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(f"{self.api_url}/health/live")

                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == "healthy" and data.get("ready"):
                        self.results.add("Liveness probe", True, "Process alive")
                    else:
                        self.results.add("Liveness probe", False, f"Status: {data.get('status')}")
                else:
                    self.results.add("Liveness probe", False, f"HTTP {response.status_code}")

        except Exception as e:
            self.results.add("Liveness probe", False, str(e))

    def _test_readiness(self):
        """Test readiness probe endpoint with deep validation."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(f"{self.api_url}/health/ready")

                if response.status_code in (200, 503):
                    data = response.json()
                    status = data.get("status")
                    ready = data.get("ready")
                    components = data.get("components", [])

                    # Extract component statuses
                    comp_status = {c["name"]: c["status"] for c in components}

                    # Determine if this is acceptable
                    if ready:
                        # Ready (healthy or degraded) is OK
                        details = f"{status.upper()} - {len(components)} components checked"
                        self.results.add("Readiness probe", True, details)
                    else:
                        # Not ready - report which component failed
                        failed = [n for n, s in comp_status.items() if s == "unhealthy"]
                        self.results.add("Readiness probe", False, f"Not ready: {', '.join(failed)}")
                else:
                    self.results.add("Readiness probe", False, f"HTTP {response.status_code}")

        except Exception as e:
            self.results.add("Readiness probe", False, str(e))

    def _test_create_case(self):
        """Test case creation via API gateway."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                payload = {
                    "title": "Smoke Test Case",
                    "description": f"E2E test case created at {datetime.now().isoformat()}",
                    "user_id": "smoke_test_user",
                }

                response = client.post(
                    f"{self.api_url}/api/v1/cases",
                    json=payload,
                )

                if response.status_code == 201:
                    data = response.json()
                    self.case_id = data.get("case_id")
                    if self.case_id:
                        self.results.add("Create case", True, f"ID: {self.case_id}")
                    else:
                        self.results.add("Create case", False, "No case_id in response")
                else:
                    self.results.add("Create case", False, f"HTTP {response.status_code}")

        except Exception as e:
            self.results.add("Create case", False, str(e))

    def _test_upload_evidence(self):
        """Test evidence upload."""
        if not self.case_id:
            self.results.add("Upload evidence", False, "Skipped (no case_id)")
            return

        try:
            # Create temporary test log file
            test_log_content = b"""2025-12-10 10:00:00 ERROR Application failed to start
2025-12-10 10:00:01 ERROR Connection refused: database unreachable
2025-12-10 10:00:02 WARN  Retrying connection (attempt 1/3)
2025-12-10 10:00:05 ERROR Connection timeout after 3 seconds
2025-12-10 10:00:06 ERROR Service startup aborted
"""

            with httpx.Client(timeout=self.timeout) as client:
                files = {"file": ("smoke_test.log", test_log_content, "text/plain")}
                data = {
                    "case_id": self.case_id,
                    "evidence_type": "log",
                    "description": "Smoke test evidence file",
                }
                headers = {"X-User-ID": "smoke_test_user"}

                response = client.post(
                    f"{self.api_url}/api/v1/evidence",
                    files=files,
                    data=data,
                    headers=headers,
                )

                if response.status_code == 201:
                    result = response.json()
                    self.evidence_id = result.get("evidence_id")
                    if self.evidence_id:
                        filename = result.get("filename", "unknown")
                        self.results.add("Upload evidence", True, f"File: {filename}")
                    else:
                        self.results.add("Upload evidence", False, "No evidence_id in response")
                else:
                    self.results.add("Upload evidence", False, f"HTTP {response.status_code}: {response.text[:100]}")

        except Exception as e:
            self.results.add("Upload evidence", False, str(e))

    def _test_ai_agent_query(self):
        """Test AI agent query endpoint."""
        if not self.case_id:
            self.results.add("AI agent query", False, "Skipped (no case_id)")
            return

        try:
            with httpx.Client(timeout=60.0) as client:  # Longer timeout for LLM
                payload = {
                    "message": "What does the error log indicate? Summarize the issue.",
                }

                response = client.post(
                    f"{self.api_url}/api/v1/agent/chat/{self.case_id}",
                    json=payload,
                )

                if response.status_code == 200:
                    data = response.json()
                    # Check for response content (different services may have different formats)
                    if data.get("response") or data.get("message") or data.get("content"):
                        response_preview = str(data)[:50] + "..."
                        self.results.add("AI agent query", True, f"Response received")
                    else:
                        self.results.add("AI agent query", False, "Empty response from agent")
                else:
                    self.results.add("AI agent query", False, f"HTTP {response.status_code}")

        except httpx.TimeoutException:
            self.results.add("AI agent query", False, "Request timeout (LLM may be slow)")
        except Exception as e:
            self.results.add("AI agent query", False, str(e))

    def _test_knowledge_search(self):
        """Test knowledge base search."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                payload = {
                    "query": "database connection error",
                    "search_mode": "keyword",
                    "limit": 5,
                }

                response = client.post(
                    f"{self.api_url}/api/v1/knowledge/search",
                    json=payload,
                )

                if response.status_code == 200:
                    data = response.json()
                    # Knowledge base may be empty in fresh install
                    if "results" in data:
                        count = len(data["results"])
                        self.results.add("Knowledge search", True, f"{count} result(s)")
                    else:
                        self.results.add("Knowledge search", False, "No 'results' field in response")
                else:
                    self.results.add("Knowledge search", False, f"HTTP {response.status_code}")

        except Exception as e:
            self.results.add("Knowledge search", False, str(e))


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="FaultMaven E2E Smoke Test - Happy Path Validation"
    )
    parser.add_argument(
        "--api-url",
        default="http://localhost:8090",
        help="API Gateway URL (default: http://localhost:8090)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="Request timeout in seconds (default: 30)",
    )

    args = parser.parse_args()

    # Run smoke test
    tester = FaultMavenSmokeTest(api_url=args.api_url, timeout=args.timeout)
    success = tester.run()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    # Check dependencies
    try:
        import httpx
        from rich.console import Console
        from rich.table import Table
        from rich.progress import Progress
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Install with: pip install httpx rich")
        sys.exit(2)

    main()

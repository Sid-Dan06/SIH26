import sys
import subprocess
from pydantic import BaseModel


class CodeExecutionRequest(BaseModel):
    language: str      # "python"
    code: str          # "print('Hello World')"


def run_python_code(code_str: str) -> dict:
    """Executes Python code safely in an isolated subprocess with a 5-second timeout."""
    try:
        result = subprocess.run(
            [sys.executable, "-c", code_str],
            capture_output=True,
            text=True,
            timeout=5,  # 👈 5-second safety timeout
        )
        if result.returncode == 0:
            return {"success": True, "output": result.stdout, "error": None}
        else:
            return {"success": False, "output": result.stdout, "error": result.stderr}
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "TimeLimitExceeded: Took longer than 5 seconds to run."}
    except Exception as e:
        return {"success": False, "output": "", "error": str(e)}
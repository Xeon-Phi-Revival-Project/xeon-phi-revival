import json
import math
import os
import pathlib
import platform
import sys
import threading

assert platform.machine() == "k1om"
assert json.loads('{"xpr": 7}')["xpr"] == 7
assert pathlib.PurePosixPath("/xpr/python").name == "python"
assert math.isclose(math.sqrt(81), 9)
assert os.name == "posix"

result = []
thread = threading.Thread(target=lambda: result.append("thread-ok"))
thread.start()
thread.join()
assert result == ["thread-ok"]

print("XPR Python core smoke PASS", sys.version.split()[0], platform.machine())

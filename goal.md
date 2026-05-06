Technical Specification for codex-developer (v11.0.0)

Project: HelloFactory-Simple

Target Mode: NEW

Persona: EXPERT

Specification:

1. Goal: Create a Python-based utility that performs two primary actions: print 'Hello Factory' to standard output and initialize a persistent log file.

2. Project Structure:
   - root/
     - README.md: Detailed documentation on app setup, usage, and expected behavior.
     - hello.py: Main execution script.
     - app.log: Log file created/appended by hello.py.

3. Functional Requirements:
   - hello.py:
     - Must output 'Hello Factory' to terminal upon execution.
     - Must open (or create) 'app.log' in append mode.
     - Must record a timestamped 'Hello Factory executed' entry into 'app.log' whenever run.
   - README.md:
     - Provide clear section headers: 'Installation', 'Usage', 'Logging Information'.
     - Include a quick start snippet to run the code.

4. Constraints:
   - Maintain clean modular structure.
   - Use absolute path handling within the script to ensure the log file location is always defined correctly relative to the project root.
   - Follow standard Python logging best practices if possible, or standard I/O if staying simple as requested.

5. Execution Order:
   - Initialize project folder.
   - Generate README.md.
   - Generate hello.py.
   - Verify script functionality and log generation.

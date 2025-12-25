# Assembly
low-level programming language with a very strong correspondence between the instructions in the language and the architecture's machine code instructions.

To Write x86 assembly code.

Download visual studio you will require this in your next weeks class

https://visualstudio.microsoft.com/downloads/

Choose Visual Studio Community

When the installer opens:

1.	Select Desktop development with C++

2.	Install

3.	This automatically includes MASM (assembly support)

🗜️Program 1 explanation (LCM)
This program calculates the least common multiple of two hardcoded unsigned integers. It first derives the greatest common divisor via the Euclidean algorithm, then computes the LCM by dividing the first input by the GCD before multiplying by the second to minimize intermediate overflow risks. Output relies on a custom procedure, U32ToDecStr, which generates decimal ASCII strings through iterative division by ten. System interactions utilize GetStdHandle and WriteConsoleA. Crucially, the code monitors the multiplication result in the EDX register; a non-zero upper half indicates the value exceeds 32-bit capacity, triggering an error exit. Otherwise, the final LCM is displayed and returned as the process exit status.
| Requirement                      | Status  | Feedback                                                                                                                                                                                         |
| :------------------------------- | :------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **x86 Assembly**                 | **Met** | Code is written in x86 assembly (MASM syntax).                                                                                                                                                   |
| **Functionality (LCM)**          | **Met** | Correctly implements the Euclidean algorithm for GCD and calculates LCM using the formula $LCM(a, b) = (a / GCD(a, b)) \cdot b$.                                                                 |
| **Exit Code Output**             | **Met** | The result is returned as the process exit code (`invoke ExitProcess, ebx`).                                                                                                                     |
| **Console Output (Extra Marks)** | **Met** | The result is printed to the console using custom procedures (`PrintZStr`, `PrintU32`).                                                                                                          |
| **Code Quality**                 | **Met** | Excellent. The code is well-commented, uses clear register conventions, and includes a robust **overflow check** after multiplication (`test edx, edx`), which is a significant mark of quality. |
| **Explanation**                  | **Met** | Concise and accurate, covering the GCD method, the output procedure, and the overflow check.                                                                                                     |

🔢Program 2: explanation (ODD sum).
This x86 assembly routine sums odd integers within a specified range by iterating through memory bounds. Using ESI for the counter and EBX for the accumulator, the logic filters odds via a bitwise test on the lowest bit. A crucial detail is the overflow protection: a secondary check compares the current index to the upper bound immediately after processing. This specific step prevents the counter from wrapping around to zero when hitting the maximum 32-bit integer (0xFFFFFFFF), avoiding an infinite loop. Once finished, the program manually converts the register value to decimal ASCII for console output and returns the final sum as the process exit code.
| Requirement                      | Status  | Feedback                                                                                                 |
| :------------------------------- | :------ | :------------------------------------------------------------------------------------------------------- |
| **x86 Assembly**                 | **Met** | Code is written in x86 assembly (MASM syntax).                                                           |
| **Functionality (Odd Sum)**      | **Met** | Correctly iterates through the range and uses `test esi, 1` to identify and sum odd numbers.             |
| **Exit Code Output**             | **Met** | The sum is returned as the process exit code (`invoke ExitProcess, ebx`).                                |
| **Console Output (Extra Marks)** | **Met** | The result is printed to the console using the same custom procedures as Program 1.                      |
| **Code Quality**                 | **Met** | Good. The code is readable and the logic is sound. The custom printing functions are reused effectively. |
| **Explanation**                  | **Met** | Concise and covers the method of selection (`bitwise test on the lowest bit`) and summation.             |

👩‍💻Program 3 explanation (StudentID × 3, manual int→ASCII)
This assembly program, written and Operating on a hardcoded 32-bit and demonstrates integer arithmetic, conversion, and console, student ID is held in memory and loaded into EAX, then multiplied by three with the mul instruction, producing a 64-bit product in EDX:EAX. If EDX is non-zero, the code treats this as an unsigned overflow and prints a clear error message before exiting with status 1. When the result fits in 32 bits, it is copied into EBX, a label string is written, and the program calls a custom U32ToDecStr routine to convert the number into a decimal ASCII representation stored in a small buffer. PrintU32, PrintZStr, and PrintNL wrap calls to GetStdHandle and WriteConsoleA so the final text and newline appear on the console, then ExitProcess returns the product as the exit code.
| Requirement                      | Program 1 (LCM)         | Program 2 (Odd Sum)     | Program 3 (ID × 3)      | Overall Status |
| :------------------------------- | :---------------------- | :---------------------- | :---------------------- | :------------- |
| **x86 Assembly**                 | Met                     | Met                     | Met                     | **Met**        |
| **Student ID in Comments**       | Met                     | Met                     | Met                     | **Met**        |
| **Correctness & Readability**    | Met (High Quality)      | Met (High Quality)      | Met (High Quality)      | **Met**        |
| **Functionality**                | Met (LCM via GCD)       | Met (Range Sum)         | Met (Multiplication)    | **Met**        |
| **Exit Code Output**             | Met                     | Met                     | Met                     | **Met**        |
| **Console Output (Extra Marks)** | Met                     | Met                     | Met                     | **Met**        |
| **Custom Int-to-ASCII**          | Met (via `U32ToDecStr`) | Met (via `U32ToDecStr`) | Met (via `U32ToDecStr`) | **Met**        |
| **Short Explanation**            | Met (Accurate)          | Met (Accurate)          | Met (Accurate)          | **Met**        |

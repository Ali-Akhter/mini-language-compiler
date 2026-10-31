# Mini C++ Lexical Analyzer

A lexical analyzer built using **C++, Flex, and regular expressions** for a personalized Mini C++-like language as part of a Compiler Construction project.

## Features

- Token recognition and classification using Flex.
- Custom identifier rules and 16 personalized keywords.
- Decimal integer and scientific notation recognition.
- Custom operators, Boolean literals, and predefined constants.
- String and character literal validation, including escape sequences.
- Line number tracking and lexical error detection.
- Token output, error reports, and token statistics.

## Project Structure


compiler-project/
├── scanner.l
├── lex.yy.cpp
├── scanner.exe
├── valid_test.txt
├── invalid_test.txt
└── output/
    ├── valid_tokens.txt
    ├── valid_errors.txt
    ├── invalid_tokens.txt
    └── invalid_errors.txt


- `scanner.l` — Flex rules and C++ implementation.
- `valid_test.txt` — Valid test cases.
- `invalid_test.txt` — Invalid test cases for error detection.
- `output/` — Generated token and error reports.

## Build and Run

Generate the C++ scanner:

```bash
flex -o lex.yy.cpp scanner.l
```

Compile it:

```bash
g++ lex.yy.cpp -o scanner.exe
```

Run the scanner:

```bash
./scanner.exe valid_test.txt
```

Replace `valid_test.txt` with `invalid_test.txt` to test lexical errors.

## Technologies

- C++
- Flex
- Regular Expressions
- MSYS2 / UCRT64


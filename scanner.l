/* =========================================================================
 * scanner.l - Lexical Analyzer
 * Compiler Construction | Project Phase 1
 * Student : Ali Akhtar
 * Reg No  : L1F23BSCS0625
 *
 * Build:  flex -o lex.yy.cpp scanner.l
 *         g++ -std=c++11 -o scanner lex.yy.cpp
 * Run:    ./scanner input.txt      (or ./scanner < input.txt)
 * ========================================================================= */

%{
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <string>
#include <iostream>
#include <sstream>

/* ---- Student-specific constant ------------------------------------------
 * Roll number 0625  ->  N = 625
 * Minimum visible characters in a string = N mod 5 + 1 = 1
 * ------------------------------------------------------------------------- */
static const int ROLL_N             = 625;
static const int MIN_STRING_VISIBLE = ROLL_N % 5 + 1;

static int tokenCount = 0;
static int errorCount = 0;

/* Helpers defined in the user-code section at the bottom */
void emitToken(const std::string& type, const std::string& lexeme);
void emitToken(const std::string& type, const std::string& lexeme, const std::string& attr);
void emitError(const std::string& msg,  const std::string& lexeme);
void handleString(const char* text, int len);
void handleChar(const char* text, int len);
%}

%option noyywrap nounput noinput yylineno

DIGIT   [0-9]
ALPHA   [A-Za-z]
ALNUM   [A-Za-z0-9]

%%

    /* ------------------------------------------------------------------
     * Whitespace and line tracking
     * ------------------------------------------------------------------ */
[ \t\r]+                 { /* skip blanks */ }
\n                       { /* yylineno is incremented automatically */ }

    /* ------------------------------------------------------------------
     * Comments: // (standard) and ## (personalized). Both are skipped.
     * ------------------------------------------------------------------ */
"//"[^\n]*               { /* single-line comment */ }
"##"[^\n]*               { /* personalized comment */ }

    /* ------------------------------------------------------------------
     * Punctuation (5 symbols): ( ) { } ;
     * ------------------------------------------------------------------ */
[(){};]                  { emitToken("PUNCTUATION", yytext); }

    /* ------------------------------------------------------------------
     * Operators
     *   +      arithmetic addition
     *   :)     relational greater-than
     *   =      assignment
     *   (-_-)  multiplication of 2 numbers
     *   (^_-)  power / exponentiation
     * ------------------------------------------------------------------ */
"+"                      { emitToken("ARITH_OP", yytext); }
":)"                     { emitToken("REL_OP", yytext); }
"="                      { emitToken("ASSIGN_OP", yytext); }
"(-_-)"                  { emitToken("MUL_OP", yytext); }
"(^_-)"                  { emitToken("POW_OP", yytext); }

    /* Incomplete / invalid custom operators (longest match keeps the
       full forms above when they are complete) */
"(-"("_"("-")?)?         { emitError("Incomplete or invalid custom operator", yytext); }
"(^"("_"("-")?)?         { emitError("Incomplete or invalid custom operator", yytext); }

    /* ------------------------------------------------------------------
     * Keywords - Category 1: C / C++ / English
     * ------------------------------------------------------------------ */
"while"|"return"|"int"|"break"|"const"|"for"|"switch"|"char" { emitToken("C_KEYWORD", yytext); }

    /* Keywords - Category 2: Roman Urdu / Urdu-inspired */
"sainsiAdad"|"shart"|"dussriShart"|"zahirKro" { emitToken("URDU_KEYWORD", yytext); }

    /* Keywords - Category 3: Personalized */
"ali"|"ali$"|"L1F23"|"#0625" { emitToken("PERSONAL_KEYWORD", yytext); }

    /* ------------------------------------------------------------------
     * Boolean literals and predefined constants
     * ------------------------------------------------------------------ */
"TheekHai"               { emitToken("BOOLEAN_TRUE", yytext); }
"NahiTheek"              { emitToken("BOOLEAN_FALSE", yytext); }
"POS_INF"                { emitToken("POSITIVE_INFINITY", yytext); }
"NEG_INF"                { emitToken("NEGATIVE_INFINITY", yytext); }

    /* ------------------------------------------------------------------
     * Numbers
     *   Scientific : 1.25e+4, 25e4          (mantissa, then e/E, sign, digits)
     *   Integer    : 25                     (decimal digits only)
     * ------------------------------------------------------------------ */
{DIGIT}+("."{DIGIT}+)?[eE][+-]?{DIGIT}+ {
        double v = std::strtod(yytext, NULL);
        std::ostringstream os;
        os << v;
        emitToken("SCIENTIFIC", yytext, "Value=" + os.str());
    }

{DIGIT}+ {
        long long v = std::strtoll(yytext, NULL, 10);
        emitToken("INTEGER", yytext, "Value=" + std::to_string(v));
    }

    /* Malformed numbers: digits immediately followed by letters/underscore
       (e.g. 0xG5, 12abc), a decimal fraction with no exponent (1.25),
       or an incomplete exponent (25e, 25e+). */
{DIGIT}+({ALPHA}|_)({ALPHA}|{DIGIT}|_)*  { emitError("Malformed Number", yytext); }
{DIGIT}+"."{DIGIT}*                      { emitError("Malformed Number", yytext); }
{DIGIT}+("."{DIGIT}*)?[eE][+-]?          { emitError("Malformed Number", yytext); }

    /* ------------------------------------------------------------------
     * Identifiers: must begin with "_i" (underscore + last letter of
     * "Ali"), then letters/digits only.
     * ------------------------------------------------------------------ */
"_i"{ALNUM}*             {
        emitToken("IDENTIFIER", yytext, "Length=" + std::to_string(yyleng));
    }

    /* ------------------------------------------------------------------
     * String literals: "..."  (escapes \n \t \" \\)
     * Unterminated string: an opening quote with no closing quote on the line.
     * ------------------------------------------------------------------ */
\"([^\"\\\n]|\\.)*\"     { handleString(yytext, yyleng); }
\"([^\"\\\n]|\\.)*       { emitError("Unterminated string", yytext); }

    /* ------------------------------------------------------------------
     * Character literals: '...'  (single char or escape \n \t \" \\ \')
     * ------------------------------------------------------------------ */
'([^'\\\n]|\\.)*'        { handleChar(yytext, yyleng); }
'([^'\\\n]|\\.)*         { emitError("Invalid character literal", yytext); }

    /* ------------------------------------------------------------------
     * Any other word-like lexeme is not a valid identifier (identifiers
     * must start with "_i"), and not a keyword/constant (matched above).
     * ------------------------------------------------------------------ */
(_|{ALPHA})({ALPHA}|{DIGIT}|_)*  { emitError("Invalid identifier pattern", yytext); }

    /* ------------------------------------------------------------------
     * Anything else is an unknown symbol
     * ------------------------------------------------------------------ */
.                        { emitError("Unknown symbol", yytext); }

%%

/* ========================================================================
 *                              User code
 * ======================================================================== */

static bool isValidStringEscape(char c)
{
    return c == 'n' || c == 't' || c == '"' || c == '\\';
}

static bool isValidCharEscape(char c)
{
    return isValidStringEscape(c) || c == '\'';
}

static char decodeEscape(char c)
{
    switch (c) {
        case 'n': return '\n';
        case 't': return '\t';
        default:  return c;      /* \" \\ \' */
    }
}

void emitToken(const std::string& type, const std::string& lexeme)
{
    ++tokenCount;
    std::cout << "Line " << yylineno << ": " << type << " -> " << lexeme << "\n";
}

void emitToken(const std::string& type, const std::string& lexeme, const std::string& attr)
{
    ++tokenCount;
    std::cout << "Line " << yylineno << ": " << type << " -> " << lexeme
              << " [" << attr << "]\n";
}

void emitError(const std::string& msg, const std::string& lexeme)
{
    ++errorCount;
    std::cout << "Line " << yylineno << ": ERROR -> " << msg
              << " \"" << lexeme << "\"\n";
}

/* text = the full lexeme, including the surrounding double quotes */
void handleString(const char* text, int len)
{
    std::string full(text, len);
    std::string body(text + 1, len - 2);

    int visible = 0;
    for (size_t i = 0; i < body.size(); ++i) {
        char c = body[i];
        if (c == '\\') {
            if (i + 1 >= body.size() || !isValidStringEscape(body[i + 1])) {
                emitError("Invalid escape sequence", full);
                return;
            }
            ++i;
            ++visible;                       /* one escape = one visible char */
        } else if (!std::isspace(static_cast<unsigned char>(c))) {
            ++visible;
        }
    }

    if (visible < MIN_STRING_VISIBLE) {
        emitError("String too short (min " + std::to_string(MIN_STRING_VISIBLE) +
                  " visible character)", full);
        return;
    }

    emitToken("STRING", full, "Length=" + std::to_string(body.size()));
}

/* text = the full lexeme, including the surrounding single quotes */
void handleChar(const char* text, int len)
{
    std::string full(text, len);
    std::string body(text + 1, len - 2);

    if (body.empty()) {
        emitError("Invalid character literal", full);
        return;
    }

    if (body[0] == '\\') {
        if (body.size() != 2) {
            emitError("Invalid character literal", full);
            return;
        }
        if (!isValidCharEscape(body[1])) {
            emitError("Invalid escape sequence", full);
            return;
        }
        int value = static_cast<unsigned char>(decodeEscape(body[1]));
        emitToken("CHAR", full, "Value=" + std::to_string(value));
        return;
    }

    if (body.size() != 1) {
        emitError("Invalid character literal", full);
        return;
    }

    int value = static_cast<unsigned char>(body[0]);
    emitToken("CHAR", full, "Value=" + std::to_string(value));
}

int main(int argc, char* argv[])
{
    if (argc > 1) {
        yyin = std::fopen(argv[1], "r");
        if (!yyin) {
            std::cerr << "Error: cannot open '" << argv[1] << "'\n";
            return 1;
        }
    }

    std::cout << "Compiler Construction | Project Phase 1\n";
    std::cout << "Student: Ali Akhtar (L1F23BSCS0625)\n";
    std::cout << "--------------------------------------------------\n";

    yylex();

    std::cout << "--------------------------------------------------\n";
    std::cout << "Total tokens: " << tokenCount
              << "   Total errors: " << errorCount << "\n";
    return 0;
}

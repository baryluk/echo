/**
 * PHP-like echo (with expressions and variables embedded into string) for D.
 * Simple example of compile time evaluation functions and mixins.
 *
 * Authors: Witold Baryluk <baryluk@smp.if.uj.edu.pl>
 * Copyright: Copyright (R) Witold Baryluk, 2007
 * Licencse:
 * BSD
 * ---
 * This package may be redistributed under the terms of the UCB BSD
 * license
 * 
 * Copyright (c) Witold Baryluk
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the Witold Baryluk nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ---
 *
 * Examples:
 * ----------------------
 * import std.stdio;
 * import echo;
 * 
 * void main() {
 *   int j = 11, i = 14;
 *   mixin(echo("echo test: i=$i j=$j Escaping: \\$j, Complicated i+j=${i+j}, End of tests."));
 *   mixin(echo2("echo2 test: i=$i j=$j Escaping: \\$j, Complicated i+j=${i+j}, End of tests."));
 * }
 * ----------------------
 * will print this output:
 * ----------------------
 * echo test: i=14 j=11 Escaping: $j, Complicated i+j=25, End of tests.
 * echo2 test: i=14 j=11 Escaping: $j, Complicated i+j=25, End of tests.
 * ----------------------
 * Bugs: Problems wiith identifiers containing Unicode chars.
 */
module echo_static;

bool isalpha(char c) {
	return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';
}
bool isnum(char c) {
	return ('0' <= c && c <= '9');
}
bool isalnum(char c) {
	return isalpha(c) || isnum(c);
}

/** Call preecho1("T $i, b, ${i-2}") returns ["T %s, b, %s", ", i, (i-2)"] */
T[][] preecho1(T)(in T[] s) {
	T[] r1 = "";
	T[] r2 = "";
	int i = 0;
	bool esc = false;
	while (i < s.length) {
		T c = s[i];
		i++;
		if (c == '$') {
			if (esc == false) {
				T c2 = s[i];
				if (c2 != '{') {
					int j = i+1;
					while (j < s.length && isalnum(s[j])) {
						j++;
					}
					r1 ~= "%s";
					r2 ~= ", " ~ s[i..j] ~ "";
					i = j;
					esc = false;
				} else {
					int j = i+2;
					while (j < s.length && s[j] != '}') {
						j++;
					}
					assert(s[j] == '}');
					r1 ~= "%s";
					r2 ~= ", (" ~ s[i+1..j] ~ ")";
					i = j+1;
					esc = false;					
				}
			} else {
				r1 ~= '$';
				esc = false;
			}
		} else if (c == '\\') {
			esc = true;
		} else {
			if (esc == true) {
				r1 ~= '\\';
				esc = false;
			}
			r1 ~= c;
		}
	}
	return [r1,r2];
}
/** Call preecho2("T $i, b, ${i-2}") returns `"T ", i, " b, ", (i-2)` */
T[] preecho2(T)(in T[] s) {
	T[] r = "";
	int i = 0;
	bool esc = false;
	bool instr = false;
	T[] sep = "";
	while (i < s.length) {
		if (i > 0) {
			sep = ", ";
		}
		T c = s[i];
		i++;
		if (c == '$') {
			if (esc == false) {
				if (instr == true) {
					r ~= "\"";
					instr = false;
				}
				T c2 = s[i];
				if (c2 != '{') {
					int j = i+1;
					while (j < s.length && isalnum(s[j])) {
						j++;
					}
					r ~= sep ~ s[i..j] ~ "";
					i = j;
					esc = false;
				} else {
					int j = i+2;
					while (j < s.length && s[j] != '}') {
						j++;
					}
					assert(s[j] == '}');
					r ~= sep ~ "(" ~ s[i+1..j] ~ ")";
					i = j+1;
					esc = false;					
				}
			} else {
				r ~= '$';
				esc = false;
			}
		} else if (c == '\\') {
			esc = true;
		} else {
			if (esc == true) {
				r ~= '\\';
				esc = false;
			}
			if (instr == false) {
				r ~= sep ~ "\"";
				instr = true;
			}
			r ~= c;
		}
	}
	if (instr == true) {
		r ~= "\"";
		instr = false;
	}

	return r;
}

/** Main macro, which use preecho1 */
T[] echo(T)(in T[] s) {
	char[][] r = preecho1(s);
	return "writefln(\"" ~ r[0] ~ "\"" ~ r[1] ~ ");\n";
}
unittest {
	assert(echo("$i") == "writefln(\"%s\", i);\n");
	assert(echo("T $ij, a") == "writefln(\"T %s, a\", ij);\n");
	assert(echo("T ${i+j}") == "writefln(\"T %s\", (i+j));\n");
}

/** Alternative main macro, which use preecho2 */
T[] echo2(T)(in T[] s) {
	return "writefln(" ~ preecho2(s) ~ ");\n";
}
unittest {
	assert(echo2("T $i, b, ${i-2}") == "writefln(\"T \", i, \", b, \", (i-2));\n");
}


import std.stdarg;
char[] cordcat(...) {
	for (int i = 0; i < _arguments.length; i++) {
		_arguments[i].print();
		if (_arguments[i] == typeid(int)) {
			return "int"; //toString(va_arg!(int)(_argptr));
		} else if (_arguments[i] == typeid(char[])) {
			return "char[]";
		} else {
			assert(0, "Unknown type in template");
		}
	}
	return "";
}

T[] tpl(T)(in T[] s) {
	return "cordcat(" ~ preecho2(s) ~ ")";
}

private import std.stdio;
//import echo;

private void main() {
	int j = 11, i = 14;

	const char[] t1 = r"echo test: i=$i j=$j Escaping: \$j, Complicated i+j=${i+j}, End of tests.";
	writefln("Template: %s", t1);
	const t1c = echo(t1);
	writefln("Code: %s", t1c);
	writef("Result: ");
	mixin(t1c);
	writefln();

	writefln();
	writefln();

	const char[] t2 = r"echo2 test: i=$i j=$j Escaping: \$j, Complicated i+j=${i+j}, End of tests.";
	writefln("Template: %s", t2);
	const t2c = echo2(t2);
	writefln("Code2: %s", t2c);
	writef("Result: ");
	mixin(t2c);
	writefln();

	writefln();
	writefln();

	const char[] t3 = r"echo2 test: i=$i j=$j Escaping: \$j, Complicated i+j=${i+j}, End of tests.";
	writefln("Template: %s", t3);
	const t3c = tpl(t3);
pragma(msg, t3c);
	writefln("Code3: %s", t3c);
	auto v = mixin(t3c);
	writef("Result: ");
	writefln("%s", v);
	writefln();
}

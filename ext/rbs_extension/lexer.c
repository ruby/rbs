#include "rbs_extension.h"

#define ONE_CHAR_PATTERN(c, t) case c: tok = next_token(state, t); break

/**
 * Returns one character at current.
 *
 * ... A B C ...
 *    ^           current => A
 * */
#define peek(state) rb_enc_mbc_to_codepoint(RSTRING_PTR(state->string) + state->current.byte_pos, RSTRING_END(state->string), rb_enc_get(state->string))

static const char *RBS_TOKENTYPE_NAMES[] = {
  "NullType",
  "pEOF",
  "ErrorToken",

  "pLPAREN",          /* ( */
  "pRPAREN",          /* ) */
  "pCOLON",           /* : */
  "pCOLON2",          /* :: */
  "pLBRACKET",        /* [ */
  "pRBRACKET",        /* ] */
  "pLBRACE",          /* { */
  "pRBRACE",          /* } */
  "pHAT",             /* ^ */
  "pARROW",           /* -> */
  "pFATARROW",        /* => */
  "pCOMMA",           /* , */
  "pBAR",             /* | */
  "pAMP",             /* & */
  "pSTAR",            /* * */
  "pSTAR2",           /* ** */
  "pDOT",             /* . */
  "pDOT3",            /* ... */
  "pBANG",            /* ! */
  "pQUESTION",        /* ? */
  "pLT",              /* < */
  "pEQ",              /* = */

  "kBOOL",            /* bool */
  "kBOT",             /* bot */
  "kCLASS",           /* class */
  "kFALSE",           /* kFALSE */
  "kINSTANCE",        /* instance */
  "kINTERFACE",       /* interface */
  "kNIL",             /* nil */
  "kSELF",            /* self */
  "kSINGLETON",       /* singleton */
  "kTOP",             /* top */
  "kTRUE",            /* true */
  "kVOID",            /* void */
  "kTYPE",            /* type */
  "kUNCHECKED",       /* unchecked */
  "kIN",              /* in */
  "kOUT",             /* out */
  "kEND",             /* end */
  "kDEF",             /* def */
  "kINCLUDE",         /* include */
  "kEXTEND",          /* extend */
  "kPREPEND",         /* prepend */
  "kALIAS",           /* alias */
  "kMODULE",          /* module */
  "kATTRREADER",      /* attr_reader */
  "kATTRWRITER",      /* attr_writer */
  "kATTRACCESSOR",    /* attr_accessor */
  "kPUBLIC",          /* public */
  "kPRIVATE",         /* private */
  "kUNTYPED",         /* untyped */

  "tLIDENT",          /* Identifiers starting with lower case */
  "tUIDENT",          /* Identifiers starting with upper case */
  "tULIDENT",         /* Identifiers starting with `_` */
  "tULLIDENT",
  "tGIDENT",          /* Identifiers starting with `$` */
  "tAIDENT",          /* Identifiers starting with `@` */
  "tA2IDENT",         /* Identifiers starting with `@@` */
  "tBANGIDENT",
  "tEQIDENT",
  "tQIDENT",          /* Quoted identifier */
  "tOPERATOR",        /* Operator identifier */

  "tCOMMENT",
  "tLINECOMMENT",

  "tDQSTRING",        /* Double quoted string */
  "tSQSTRING",        /* Single quoted string */
  "tINTEGER",         /* Integer */
  "tSYMBOL",          /* Symbol */
  "tDQSYMBOL",
  "tSQSYMBOL",
  "tANNOTATION",      /* Annotation */
};

token NullToken = { NullType };
position NullPosition = { -1, -1, -1, -1 };
range NULL_RANGE = { { -1, -1, -1, -1 }, { -1, -1, -1, -1 } };

const char *token_type_str(enum TokenType type) {
  return RBS_TOKENTYPE_NAMES[type];
}

unsigned int peekn(lexstate *state, unsigned int chars[], size_t length) {
  int byteoffset = 0;

  rb_encoding *encoding = rb_enc_get(state->string);
  char *start = RSTRING_PTR(state->string) + state->current.byte_pos;
  char *end = RSTRING_END(state->string);

  for (size_t i = 0; i < length; i++)
  {
    chars[i] = rb_enc_mbc_to_codepoint(start + byteoffset, end, encoding);
    byteoffset += rb_enc_codelen(chars[i], rb_enc_get(state->string));
  }

  return byteoffset;
}

int token_chars(token tok) {
  return tok.range.end.char_pos - tok.range.start.char_pos;
}

int token_bytes(token tok) {
  return RANGE_BYTES(tok.range);
}

/**
 * ... token ...
 *    ^             start
 *          ^       current
 *
 * */
token next_token(lexstate *state, enum TokenType type) {
  token t;

  t.type = type;
  t.range.start = state->start;
  t.range.end = state->current;
  state->start = state->current;
  state->first_token_of_line = false;

  return t;
}

void advance_skip(lexstate *state, unsigned int c, bool skip) {
  int len = rb_enc_codelen(c, rb_enc_get(state->string));

  state->current.char_pos += 1;
  state->current.byte_pos += len;

  if (c == '\n') {
    state->current.line += 1;
    state->current.column = 0;
    state->first_token_of_line = true;
  } else {
    state->current.column += 1;
  }

  if (skip) {
    state->start = state->current;
  }
}

void advance_char(lexstate *state, unsigned int c) {
  advance_skip(state, c, false);
}

void skip_char(lexstate *state, unsigned int c) {
  advance_skip(state, c, true);
}

void skip(lexstate *state) {
  unsigned char c = peek(state);
  skip_char(state, c);
}

void advance(lexstate *state) {
  unsigned char c = peek(state);
  advance_char(state, c);
}

/*
  1. Peek one character from state
  2. If read characetr equals to given `c`, skip the character and return true.
  3. Return false otherwise.
*/
static bool advance_next_character_if(lexstate *state, unsigned int c) {
  if (peek(state) == c) {
    advance_char(state, c);
    return true;
  } else {
    return false;
  }
}

/*
   ... 0 1 ...
        ^           current
          ^         current (return)
*/
static token lex_number(lexstate *state) {
  unsigned int c;

  while (true) {
    c = peek(state);

    if (rb_isdigit(c) || c == '_') {
      advance_char(state, c);
    } else {
      break;
    }
  }

  return next_token(state, tINTEGER);
}

/*
  lex_hyphen ::=  -       (tOPERATOR)
               |  - @     (tOPERATOR)
               |  - >     (pARROW)
               |  - 1 ... (tINTEGER)
*/
static token lex_hyphen(lexstate* state) {
  if (advance_next_character_if(state, '>')) {
    return next_token(state, pARROW);
  } else if (advance_next_character_if(state, '@')) {
    return next_token(state, tOPERATOR);
  } else {
    unsigned int c = peek(state);

    if (rb_isdigit(c)) {
      advance_char(state, c);
      return lex_number(state);
    } else {
      return next_token(state, tOPERATOR);
    }
  }
}

/*
  lex_plus ::= +
             | + @
             | + \d
*/
static token lex_plus(lexstate *state) {
  if (advance_next_character_if(state, '@')) {
    return next_token(state, tOPERATOR);
  } else if (rb_isdigit(peek(state))) {
    return lex_number(state);
  } else {
    return next_token(state, tOPERATOR);
  }
}

/*
  lex_dot ::= .         pDOT
            | . . .     pDOT3
*/
static token lex_dot(lexstate *state) {
  unsigned int cs[2];

  peekn(state, cs, 2);

  if (cs[0] == '.' && cs[1] == '.') {
    advance_char(state, '.');
    advance_char(state, '.');
    return next_token(state, pDOT3);
  } else {
    return next_token(state, pDOT);
  }
}

/*
  lex_eq ::= =
           | ==
           | ===
           | =~
           | =>
*/
static token lex_eq(lexstate *state) {
  unsigned int cs[2];
  peekn(state, cs, 2);

  if (cs[0] == '=' && cs[1] == '=') {
    // ===
    advance_char(state, cs[0]);
    advance_char(state, cs[1]);
    return next_token(state, tOPERATOR);
  } else if (cs[0] == '=') {
    // ==
    advance_char(state, cs[0]);
    return next_token(state, tOPERATOR);
  } else if (cs[0] == '~') {
    // =~
    advance_char(state, cs[0]);
    return next_token(state, tOPERATOR);
  } else if (cs[0] == '>') {
    // =>
    advance_char(state, cs[0]);
    return next_token(state, pFATARROW);
  } else {
    return next_token(state, pEQ);
  }
}

/*
  underscore ::= _A        tULIDENT
               | _a        tULLIDENT
               | _         tULLIDENT
*/
static token lex_underscore(lexstate *state) {
  unsigned int c;

  c = peek(state);

  if ('A' <= c && c <= 'Z') {
    advance_char(state, c);

    while (true) {
      c = peek(state);

      if (rb_isalnum(c) || c == '_') {
        // ok
        advance_char(state, c);
      } else {
        break;
      }
    }

    return next_token(state, tULIDENT);
  } else if (rb_isalnum(c) || c == '_') {
    advance_char(state, c);

    while (true) {
      c = peek(state);

      if (rb_isalnum(c) || c == '_') {
        // ok
        advance_char(state, c);
      } else {
        break;
      }
    }

    if (c == '!') {
      advance_char(state, c);
      return next_token(state, tBANGIDENT);
    } else if (c == '=') {
      advance_char(state, c);
      return next_token(state, tEQIDENT);
    } else {
      return next_token(state, tULLIDENT);
    }
  } else {
    return next_token(state, tULLIDENT);
  }
}

static bool is_opr(unsigned int c) {
  switch (c) {
  case ':':
  case ';':
  case '=':
  case '.':
  case ',':
  case '!':
  case '"':
  case '$':
  case '%':
  case '&':
  case '(':
  case ')':
  case '-':
  case '+':
  case '~':
  case '|':
  case '\\':
  case '\'':
  case '[':
  case ']':
  case '{':
  case '}':
  case '*':
  case '/':
  case '<':
  case '>':
  case '^':
    return true;
  default:
    return false;
  }
}

static token lex_global(lexstate *state) {
  unsigned int c;

  c = peek(state);

  if (rb_isspace(c) || c == 0) {
    return next_token(state, ErrorToken);
  }

  if (rb_isdigit(c)) {
    // `$` [`0`-`9`]+
    advance_char(state, c);

    while (true) {
      c = peek(state);
      if (rb_isdigit(c)) {
        advance_char(state, c);
      } else {
        return next_token(state, tGIDENT);
      }
    }
  }

  if (c == '-') {
    // `$` `-` [a-zA-Z0-9_]
    advance_char(state, c);
    c = peek(state);

    if (rb_isalnum(c) || c == '_') {
      advance_char(state, c);
      return next_token(state, tGIDENT);
    } else {
      return next_token(state, ErrorToken);
    }
  }

  switch (c) {
  case '~':
  case '*':
  case '$':
  case '?':
  case '!':
  case '@':
  case '\\':
  case '/':
  case ';':
  case ',':
  case '.':
  case '=':
  case ':':
  case '<':
  case '>':
  case '"':
  case '&':
  case '\'':
  case '`':
  case '+':
    advance_char(state, c);
    return next_token(state, tGIDENT);

  default:
    if (is_opr(c) || c == 0) {
      return next_token(state, ErrorToken);
    }

    while (true) {
      advance_char(state, c);
      c = peek(state);

      if (rb_isspace(c) || is_opr(c) || c == 0) {
        break;
      }
    }

    return next_token(state, tGIDENT);
  }
}

void pp(VALUE object) {
  VALUE inspect = rb_funcall(object, rb_intern("inspect"), 0);
  printf("pp >> %s\n", RSTRING_PTR(inspect));
}

static token lex_ident(lexstate *state, enum TokenType default_type) {
  unsigned int c;
  token tok;

  while (true) {
    c = peek(state);
    if (rb_isalnum(c) || c == '_') {
      advance_char(state, c);
    } else if (c == '!') {
      advance_char(state, c);
      tok = next_token(state, tBANGIDENT);
      break;
    } else if (c == '=') {
      advance_char(state, c);
      tok = next_token(state, tEQIDENT);
      break;
    } else {
      tok = next_token(state, default_type);
      break;
    }
  }

  if (tok.type == tLIDENT) {
    VALUE string = rb_enc_str_new(
      RSTRING_PTR(state->string) + tok.range.start.byte_pos,
      RANGE_BYTES(tok.range),
      rb_enc_get(state->string)
    );

    VALUE type = rb_hash_aref(RBS_Parser_KEYWORDS, string);
    if (FIXNUM_P(type)) {
      tok.type = FIX2INT(type);
    }
  }

  return tok;
}

static token lex_comment(lexstate *state, enum TokenType type) {
  unsigned int c;

  c = peek(state);
  if (c == ' ') {
    advance_char(state, c);
  }

  while (true) {
    c = peek(state);

    if (c == '\n' || c == '\0') {
      break;
    } else {
      advance_char(state, c);
    }
  }

  token tok = next_token(state, type);

  skip_char(state, c);

  return tok;
}

/*
   ... " ... " ...
      ^               start
        ^             current
              ^       current (after)
*/
static token lex_dqstring(lexstate *state) {
  unsigned int c;

  while (true) {
    c = peek(state);
    advance_char(state, c);

    if (c == '\\') {
      if (peek(state) == '"') {
        advance_char(state, c);
        c = peek(state);
      }
    } else if (c == '"') {
      break;
    }
  }

  return next_token(state, tDQSTRING);
}

/*
   ... @ foo ...
      ^             start
        ^           current
            ^       current (return)

   ... @ @ foo ...
      ^               start
        ^             current
              ^       current (return)
*/
static token lex_ivar(lexstate *state) {
  unsigned int c;

  enum TokenType type = tAIDENT;

  c = peek(state);

  if (c == '@') {
    type = tA2IDENT;
    advance_char(state, c);
    c = peek(state);
  }

  if (rb_isalpha(c) || c == '_') {
    advance_char(state, c);
    c = peek(state);
  } else {
    return next_token(state, ErrorToken);
  }

  while (rb_isalnum(c) || c == '_') {
    advance_char(state, c);
    c = peek(state);
  }

  return next_token(state, type);
}

/*
   ... ' ... ' ...
      ^               start
        ^             current
              ^       current (after)
*/
static token lex_sqstring(lexstate *state) {
  unsigned int c;

  c = peek(state);

  while (true) {
    c = peek(state);
    advance_char(state, c);

    if (c == '\\') {
      if (peek(state) == '\'') {
        advance_char(state, c);
        c = peek(state);
      }
    } else if (c == '\'') {
      break;
    }
  }

  return next_token(state, tSQSTRING);
}

#define EQPOINTS2(c0, c1, s) (c0 == s[0] && c1 == s[1])
#define EQPOINTS3(c0, c1, c2, s) (c0 == s[0] && c1 == s[1] && c2 == s[2])

/*
   ... : @ ...
      ^          start
        ^        current
          ^      current (return)
*/
static token lex_colon_symbol(lexstate *state) {
  unsigned int c[3];
  peekn(state, c, 3);

  switch (c[0]) {
    case '|':
    case '&':
    case '/':
    case '%':
    case '~':
    case '`':
    case '^':
      advance_char(state, c[0]);
      return next_token(state, tSYMBOL);
    case '=':
      if (EQPOINTS2(c[0], c[1], "=~")) {
        // :=~
        advance_char(state, c[0]);
        advance_char(state, c[1]);
        return next_token(state, tSYMBOL);
      } else if (EQPOINTS3(c[0], c[1], c[2], "===")) {
        // :===
        advance_char(state, c[0]);
        advance_char(state, c[1]);
        advance_char(state, c[2]);
        return next_token(state, tSYMBOL);
      } else if (EQPOINTS2(c[0], c[1], "==")) {
        // :==
        advance_char(state, c[0]);
        advance_char(state, c[1]);
        return next_token(state, tSYMBOL);
      }
      break;
    case '<':
      if (EQPOINTS3(c[0], c[1], c[2], "<=>")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
        advance_char(state, c[2]);
      } else if (EQPOINTS2(c[0], c[1], "<=") || EQPOINTS2(c[0], c[1], "<<")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        advance_char(state, c[0]);
      }
      return next_token(state, tSYMBOL);
    case '>':
      if (EQPOINTS2(c[0], c[1], ">=") || EQPOINTS2(c[0], c[1], ">>")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        advance_char(state, c[0]);
      }
      return next_token(state, tSYMBOL);
    case '-':
    case '+':
      if (EQPOINTS2(c[0], c[1], "+@") || EQPOINTS2(c[0], c[1], "-@")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        advance_char(state, c[0]);
      }
      return next_token(state, tSYMBOL);
    case '*':
      if (EQPOINTS2(c[0], c[1], "**")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        advance_char(state, c[0]);
      }
      return next_token(state, tSYMBOL);
    case '[':
      if (EQPOINTS3(c[0], c[1], c[2], "[]=")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
        advance_char(state, c[2]);
      } else if (EQPOINTS2(c[0], c[1], "[]")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        break;
      }
      return next_token(state, tSYMBOL);
    case '!':
      if (EQPOINTS2(c[0], c[1], "!=") || EQPOINTS2(c[0], c[1], "!~")) {
        advance_char(state, c[0]);
        advance_char(state, c[1]);
      } else {
        advance_char(state, c[0]);
      }
      return next_token(state, tSYMBOL);
    case '@': {
      advance_char(state, '@');
      token tok = lex_ivar(state);
      if (tok.type != ErrorToken) {
        tok.type = tSYMBOL;
      }
      return tok;
    }
    case '$': {
      advance_char(state, '$');
      token tok = lex_global(state);
      if (tok.type != ErrorToken) {
        tok.type = tSYMBOL;
      }
      return tok;
    }
    case '\'': {
      position start = state->start;
      advance_char(state, '\'');
      token tok = lex_sqstring(state);
      tok.type = tSQSYMBOL;
      tok.range.start = start;
      return tok;
    }
    case '"': {
      position start = state->start;
      advance_char(state, '"');
      token tok = lex_dqstring(state);
      tok.type = tDQSYMBOL;
      tok.range.start = start;
      return tok;
    }
    default:
      if (rb_isalpha(c[0]) || c[0] == '_') {
        position start = state->start;
        token tok = lex_ident(state, NullType);
        tok.range.start = start;

        if (peek(state) == '?') {
          if (tok.type != tBANGIDENT && tok.type != tEQIDENT) {
            skip_char(state, '?');
            tok.range.end = state->current;
          }
        }

        tok.type = tSYMBOL;
        return tok;
      }
  }

  return next_token(state, pCOLON);
}

/*
   ... : : ...
      ^          start
        ^        current
          ^      current (return)

   ... :   ...
      ^          start
        ^        current (lex_colon_symbol)
*/
static token lex_colon(lexstate *state) {
  unsigned int c = peek(state);

  if (c == ':') {
    advance_char(state, c);
    return next_token(state, pCOLON2);
  } else {
    return lex_colon_symbol(state);
  }
}

/*
  lex_lt ::= <       (pLT)
           | < <     (tOPERATOR)
           | < =     (tOPERATOR)
           | < = >   (tOPERATOR)
*/
static token lex_lt(lexstate *state) {
  if (advance_next_character_if(state, '<')) {
    return next_token(state, tOPERATOR);
  } else if (advance_next_character_if(state, '=')) {
    advance_next_character_if(state, '>');
    return next_token(state, tOPERATOR);
  } else {
    return next_token(state, pLT);
  }
}

/*
  lex_gt ::= >
           | > =
           | > >
*/
static token lex_gt(lexstate *state) {
  advance_next_character_if(state, '=') || advance_next_character_if(state, '>');
  return next_token(state, tOPERATOR);
}

/*
    ... `%` `a` `{` ... `}` ...
       ^                         start
           ^                     current
                           ^     current (exit)
                    ---          token
*/
static token lex_percent(lexstate *state) {
  unsigned int cs[2];
  unsigned int end_char;

  peekn(state, cs, 2);

  if (cs[0] != 'a') {
    return next_token(state, tOPERATOR);
  }

  switch (cs[1])
  {
  case '{':
    end_char = '}';
    break;
  case '(':
    end_char = ')';
    break;
  case '[':
    end_char = ']';
    break;
  case '|':
    end_char = '|';
    break;
  case '<':
    end_char = '>';
    break;
  default:
    return next_token(state, tOPERATOR);
  }

  advance_char(state, cs[0]);
  advance_char(state, cs[1]);

  unsigned int c;

  while ((c = peek(state))) {
    if (c == end_char) {
      advance_char(state, c);
      return next_token(state, tANNOTATION);
    }
    advance_char(state, c);
  }

  return next_token(state, ErrorToken);
}

/*
  bracket ::= [       (pLBRACKET)
             * ^
            | [ ]     (tOPERATOR)
             * ^ $
            | [ ] =   (tOPERATOR)
             * ^   $
*/
static token lex_bracket(lexstate *state) {
  if (advance_next_character_if(state, ']')) {
    advance_next_character_if(state, '=');
    return next_token(state, tOPERATOR);
  } else {
    return next_token(state, pLBRACKET);
  }
}

/*
  bracket ::= *
            | * *
*/
static token lex_star(lexstate *state) {
  if (advance_next_character_if(state, '*')) {
    return next_token(state, pSTAR2);
  } else {
    return next_token(state, pSTAR);
  }
}

/*
  bang ::= !
         | ! =
         | ! ~
*/
static token lex_bang(lexstate *state) {
  advance_next_character_if(state, '=') || advance_next_character_if(state, '~');
  return next_token(state, tOPERATOR);
}

/*
  backquote ::= `            (tOPERATOR)
              | `[^ :][^`]`  (tQIDENT)
*/
static token lex_backquote(lexstate *state) {
  unsigned int c = peek(state);

  if (c == ' ' || c == ':') {
    return next_token(state, tOPERATOR);
  } else {
    while (true) {
      if (c == '`') {
        break;
      }

      c = peek(state);
      advance_char(state, c);
    }

    return next_token(state, tQIDENT);
  }
}

token rbsparser_next_token(lexstate *state) {
  token tok = NullToken;

  unsigned int c;
  bool skipping = true;

  while (skipping) {
    c = peek(state);

    switch (c) {
    case ' ':
    case '\t':
    case '\n':
      // nop
      skip_char(state, c);
      break;
    case '\0':
      return next_token(state, pEOF);
    default:
      advance_char(state, c);
      skipping = false;
      break;
    }
  }

  /* ... c d ..                */
  /*      ^     state->current */
  /*    ^       start          */
  switch (c) {
    case '\0': tok = next_token(state, pEOF);
    ONE_CHAR_PATTERN('(', pLPAREN);
    ONE_CHAR_PATTERN(')', pRPAREN);
    ONE_CHAR_PATTERN(']', pRBRACKET);
    ONE_CHAR_PATTERN('{', pLBRACE);
    ONE_CHAR_PATTERN('}', pRBRACE);
    ONE_CHAR_PATTERN(',', pCOMMA);
    ONE_CHAR_PATTERN('|', pBAR);
    ONE_CHAR_PATTERN('^', pHAT);
    ONE_CHAR_PATTERN('&', pAMP);
    ONE_CHAR_PATTERN('?', pQUESTION);
    ONE_CHAR_PATTERN('/', tOPERATOR);
    ONE_CHAR_PATTERN('~', tOPERATOR);
    case '[':
      tok = lex_bracket(state);
      break;
    case '-':
      tok = lex_hyphen(state);
      break;
    case '+':
      tok = lex_plus(state);
      break;
    case '*':
      tok = lex_star(state);
      break;
    case '<':
      tok = lex_lt(state);
      break;
    case '=':
      tok = lex_eq(state);
      break;
    case '>':
      tok = lex_gt(state);
      break;
    case '!':
      tok = lex_bang(state);
      break;
    case '#':
      if (state->first_token_of_line) {
        tok = lex_comment(state, tLINECOMMENT);
      } else {
        tok = lex_comment(state, tCOMMENT);
      }
      break;
    case ':':
      tok = lex_colon(state);
      break;
    case '.':
      tok = lex_dot(state);
      break;
    case '_':
      tok = lex_underscore(state);
      break;
    case '$':
      tok = lex_global(state);
      break;
    case '@':
      tok = lex_ivar(state);
      break;
    case '"':
      tok = lex_dqstring(state);
      break;
    case '\'':
      tok = lex_sqstring(state);
      break;
    case '%':
      tok = lex_percent(state);
      break;
    case '`':
      tok = lex_backquote(state);
      break;
    default:
      if (rb_isalpha(c) && rb_isupper(c)) {
        tok = lex_ident(state, tUIDENT);
      }
      if (rb_isalpha(c) && rb_islower(c)) {
        tok = lex_ident(state, tLIDENT);
      }
      if (rb_isdigit(c)) {
        tok = lex_number(state);
      }
  }

  if (tok.type == NullType) {
    tok = next_token(state, ErrorToken);
  }

  return tok;
}

char *peek_token(lexstate *state, token tok) {
  return RSTRING_PTR(state->string) + tok.range.start.byte_pos;
}

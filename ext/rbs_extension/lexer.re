#include "rbs_extension.h"

token __rbsparser_next_token(lexstate *state) {
  lexstate backup;

start:
  backup = *state;

  /*!re2c
      re2c:flags:u = 1;
      re2c:api:style = free-form;
      re2c:flags:input = custom;
      re2c:define:YYCTYPE = "unsigned int";
      re2c:define:YYPEEK = "peek(state)";
      re2c:define:YYSKIP = "skip(state);";
      re2c:define:YYBACKUP = "backup = *state;";
      re2c:define:YYRESTORE = "*state = backup;";
      re2c:yyfill:enable  = 0;

      word = [a-zA-Z0-9_];

      operator = "/" | "~" | "[]" | "[]=" | "!" | "!=" | "!~" | "-" | "-@" | "+" | "+@"
               | "==" | "===" | "=~" | "<<" | "<=" | "<=>" | ">" | ">=" | ">>" | "%";

      "("   { return next_token(state, pLPAREN); }
      ")"   { return next_token(state, pRPAREN); }
      "["   { return next_token(state, pLBRACKET); }
      "]"   { return next_token(state, pRBRACKET); }
      "{"   { return next_token(state, pLBRACE); }
      "}"   { return next_token(state, pRBRACE); }
      ","   { return next_token(state, pCOMMA); }
      "|"   { return next_token(state, pBAR); }
      "^"   { return next_token(state, pHAT); }
      "&"   { return next_token(state, pAMP); }
      "?"   { return next_token(state, pQUESTION); }
      "*"   { return next_token(state, pSTAR); }
      "**"  { return next_token(state, pSTAR2); }
      "."   { return next_token(state, pDOT); }
      "..." { return next_token(state, pDOT3); }
      "`"   {  return next_token(state, tOPERATOR); }
      "`"   [^ :\x00] [^`\x00]* "`" { return next_token(state, tQIDENT); }
      "->"  { return next_token(state, pARROW); }
      "=>"  { return next_token(state, pFATARROW); }
      "="   { return next_token(state, pEQ); }
      ":"   { return next_token(state, pCOLON); }
      "::"  { return next_token(state, pCOLON2); }
      "<"   { return next_token(state, pLT); }
      operator  { return next_token(state, tOPERATOR); }

      number = [0-9] [0-9_]*;
      ("-"|"+")? number    { return next_token(state, tINTEGER); }

      "%a{" [^}\x00]* "}"  { return next_token(state, tANNOTATION); }
      "%a(" [^)\x00]* ")"  { return next_token(state, tANNOTATION); }
      "%a[" [^\]\x00]* "]" { return next_token(state, tANNOTATION); }
      "%a|" [^|\x00]* "|"  { return next_token(state, tANNOTATION); }
      "%a<" [^>\x00]* ">"  { return next_token(state, tANNOTATION); }

      "#" (. \ [\x00])*    {
        return next_token(
          state,
          state->first_token_of_line ? tLINECOMMENT : tCOMMENT
        );
      }

      dqstring = ["] ("\\"["] | [^"\x00])* ["];
      sqstring = ['] ("\\"['] | [^'\x00])* ['];

      dqstring     { return next_token(state, tDQSTRING); }
      sqstring     { return next_token(state, tSQSTRING); }
      ":" dqstring { return next_token(state, tDQSYMBOL); }
      ":" sqstring { return next_token(state, tSQSYMBOL); }

      identifier = [a-zA-Z_] word* [!?=]?;
      symbol_opr = ":|" | ":&" | ":/" | ":%" | ":~" | ":`" | ":^"
                 | ":==" | ":=~" | ":===" | ":!" | ":!=" | ":!~"
                 | ":<" | ":<=" | ":<<" | ":<=>" | ":>" | ":>=" | ":>>"
                 | ":-" | ":-@" | ":+" | ":+@" | ":*" | ":**" | ":[]" | ":[]=";

      global_ident = [0-9]+
                   | "-" [a-zA-Z0-9_]
                   | [~*$?!@\\/;,.=:<>"&'`+]
                   | [^ \t\r\n:;=.,!"$%&()-+~|\\'[\]{}*/<>^\x00]+;

      ":" identifier     { return next_token(state, tSYMBOL); }
      ":@" identifier    { return next_token(state, tSYMBOL); }
      ":@@" identifier   { return next_token(state, tSYMBOL); }
      ":$" global_ident  { return next_token(state, tSYMBOL); }
      symbol_opr         { return next_token(state, tSYMBOL); }


      [a-z] word*           { return next_token(state, tLIDENT); }
      [A-Z] word*           { return next_token(state, tUIDENT); }
      "_" [a-z0-9_] word*   { return next_token(state, tULLIDENT); }
      "_" [A-Z] word*       { return next_token(state, tULIDENT); }
      "_"                   { return next_token(state, tULLIDENT); }
      [a-zA-Z_] word* "!"   { return next_token(state, tBANGIDENT); }
      [a-zA-Z_] word* "="   { return next_token(state, tEQIDENT); }

      "@" [a-zA-Z_] word*   { return next_token(state, tAIDENT); }
      "@@" [a-zA-Z_] word*  { return next_token(state, tA2IDENT); }

      "$" global_ident      { return next_token(state, tGIDENT); }

      skip = [ \t\n]+;

      skip     { state->start = state->current; goto start; }
      "\x00"   { return next_token(state, pEOF); }
      *        { return next_token(state, ErrorToken); }
  */
}

token rbsparser_next_token(lexstate *state) {
  token t = __rbsparser_next_token(state);

  if (t.type == tLIDENT) {
    // may be a keyword
    VALUE string = rb_enc_str_new(
      RSTRING_PTR(state->string) + t.range.start.byte_pos,
      RANGE_BYTES(t.range),
      rb_enc_get(state->string)
    );

    VALUE type = rb_hash_aref(RBS_Parser_KEYWORDS, string);
    if (FIXNUM_P(type)) {
      t.type = FIX2INT(type);
    }
  }

  return t;
}

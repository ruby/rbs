#include "rbs/lexer.h"

rbs_token_t rbsparser_next_token(lexstate *state) {
  lexstate backup;

  backup = *state;

  /*!re2c
      re2c:flags:u = 1;
      re2c:api:style = free-form;
      re2c:flags:input = custom;
      re2c:define:YYCTYPE = "unsigned int";
      re2c:define:YYPEEK = "rbs_peek(state)";
      re2c:define:YYSKIP = "rbs_skip(state);";
      re2c:define:YYBACKUP = "backup = *state;";
      re2c:define:YYRESTORE = "*state = backup;";
      re2c:yyfill:enable  = 0;

      word = [a-zA-Z0-9_];

      operator = "/" | "~" | "[]=" | "!" | "!=" | "!~" | "-" | "-@" | "+" | "+@"
               | "==" | "===" | "=~" | "<<" | "<=" | "<=>" | ">" | ">=" | ">>" | "%";

      "("   { return rbs_next_token(state, pLPAREN); }
      ")"   { return rbs_next_token(state, pRPAREN); }
      "["   { return rbs_next_token(state, pLBRACKET); }
      "]"   { return rbs_next_token(state, pRBRACKET); }
      "{"   { return rbs_next_token(state, pLBRACE); }
      "}"   { return rbs_next_token(state, pRBRACE); }
      ","   { return rbs_next_token(state, pCOMMA); }
      "|"   { return rbs_next_token(state, pBAR); }
      "^"   { return rbs_next_token(state, pHAT); }
      "&"   { return rbs_next_token(state, pAMP); }
      "?"   { return rbs_next_token(state, pQUESTION); }
      "*"   { return rbs_next_token(state, pSTAR); }
      "**"  { return rbs_next_token(state, pSTAR2); }
      "."   { return rbs_next_token(state, pDOT); }
      "..." { return rbs_next_token(state, pDOT3); }
      "`"   {  return rbs_next_token(state, tOPERATOR); }
      "`"   [^ :\x00] [^`\x00]* "`" { return rbs_next_token(state, tQIDENT); }
      "->"  { return rbs_next_token(state, pARROW); }
      "=>"  { return rbs_next_token(state, pFATARROW); }
      "="   { return rbs_next_token(state, pEQ); }
      ":"   { return rbs_next_token(state, pCOLON); }
      "::"  { return rbs_next_token(state, pCOLON2); }
      "<"   { return rbs_next_token(state, pLT); }
      "[]"  { return rbs_next_token(state, pAREF_OPR); }
      operator  { return rbs_next_token(state, tOPERATOR); }

      number = [0-9] [0-9_]*;
      ("-"|"+")? number    { return rbs_next_token(state, tINTEGER); }

      "%a{" [^}\x00]* "}"  { return rbs_next_token(state, tANNOTATION); }
      "%a(" [^)\x00]* ")"  { return rbs_next_token(state, tANNOTATION); }
      "%a[" [^\]\x00]* "]" { return rbs_next_token(state, tANNOTATION); }
      "%a|" [^|\x00]* "|"  { return rbs_next_token(state, tANNOTATION); }
      "%a<" [^>\x00]* ">"  { return rbs_next_token(state, tANNOTATION); }

      "#" (. \ [\x00])*    {
        return rbs_next_token(
          state,
          state->first_token_of_line ? tLINECOMMENT : tCOMMENT
        );
      }

      "alias"         { return rbs_next_token(state, kALIAS); }
      "attr_accessor" { return rbs_next_token(state, kATTRACCESSOR); }
      "attr_reader"   { return rbs_next_token(state, kATTRREADER); }
      "attr_writer"   { return rbs_next_token(state, kATTRWRITER); }
      "bool"          { return rbs_next_token(state, kBOOL); }
      "bot"           { return rbs_next_token(state, kBOT); }
      "class"         { return rbs_next_token(state, kCLASS); }
      "def"           { return rbs_next_token(state, kDEF); }
      "end"           { return rbs_next_token(state, kEND); }
      "extend"        { return rbs_next_token(state, kEXTEND); }
      "false"         { return rbs_next_token(state, kFALSE); }
      "in"            { return rbs_next_token(state, kIN); }
      "include"       { return rbs_next_token(state, kINCLUDE); }
      "instance"      { return rbs_next_token(state, kINSTANCE); }
      "interface"     { return rbs_next_token(state, kINTERFACE); }
      "module"        { return rbs_next_token(state, kMODULE); }
      "nil"           { return rbs_next_token(state, kNIL); }
      "out"           { return rbs_next_token(state, kOUT); }
      "prepend"       { return rbs_next_token(state, kPREPEND); }
      "private"       { return rbs_next_token(state, kPRIVATE); }
      "public"        { return rbs_next_token(state, kPUBLIC); }
      "self"          { return rbs_next_token(state, kSELF); }
      "singleton"     { return rbs_next_token(state, kSINGLETON); }
      "top"           { return rbs_next_token(state, kTOP); }
      "true"          { return rbs_next_token(state, kTRUE); }
      "type"          { return rbs_next_token(state, kTYPE); }
      "unchecked"     { return rbs_next_token(state, kUNCHECKED); }
      "untyped"       { return rbs_next_token(state, kUNTYPED); }
      "void"          { return rbs_next_token(state, kVOID); }
      "use"           { return rbs_next_token(state, kUSE); }
      "as"            { return rbs_next_token(state, kAS); }
      "__todo__"      { return rbs_next_token(state, k__TODO__); }

      unicode_char = "\\u" [0-9a-fA-F]{4};
      oct_char = "\\x" [0-9a-f]{1,2};
      hex_char = "\\" [0-7]{1,3};

      dqstring = ["] (unicode_char | oct_char | hex_char | "\\" [^xu] | [^\\"\x00])* ["];
      sqstring = ['] ("\\"['\\] | [^'\x00])* ['];

      dqstring     { return rbs_next_token(state, tDQSTRING); }
      sqstring     { return rbs_next_token(state, tSQSTRING); }
      ":" dqstring { return rbs_next_token(state, tDQSYMBOL); }
      ":" sqstring { return rbs_next_token(state, tSQSYMBOL); }

      identifier = [a-zA-Z_] word* [!?=]?;
      symbol_opr = ":|" | ":&" | ":/" | ":%" | ":~" | ":`" | ":^"
                 | ":==" | ":=~" | ":===" | ":!" | ":!=" | ":!~"
                 | ":<" | ":<=" | ":<<" | ":<=>" | ":>" | ":>=" | ":>>"
                 | ":-" | ":-@" | ":+" | ":+@" | ":*" | ":**" | ":[]" | ":[]=";

      global_ident = [0-9]+
                   | "-" [a-zA-Z0-9_]
                   | [~*$?!@\\/;,.=:<>"&'`+]
                   | [^ \t\r\n:;=.,!"$%&()-+~|\\'[\]{}*/<>^\x00]+;

      ":" identifier     { return rbs_next_token(state, tSYMBOL); }
      ":@" identifier    { return rbs_next_token(state, tSYMBOL); }
      ":@@" identifier   { return rbs_next_token(state, tSYMBOL); }
      ":$" global_ident  { return rbs_next_token(state, tSYMBOL); }
      symbol_opr         { return rbs_next_token(state, tSYMBOL); }

      [a-z] word*           { return rbs_next_token(state, tLIDENT); }
      [A-Z] word*           { return rbs_next_token(state, tUIDENT); }
      "_" [a-z0-9_] word*   { return rbs_next_token(state, tULLIDENT); }
      "_" [A-Z] word*       { return rbs_next_token(state, tULIDENT); }
      "_"                   { return rbs_next_token(state, tULLIDENT); }
      [a-zA-Z_] word* "!"   { return rbs_next_token(state, tBANGIDENT); }
      [a-zA-Z_] word* "="   { return rbs_next_token(state, tEQIDENT); }

      "@" [a-zA-Z_] word*   { return rbs_next_token(state, tAIDENT); }
      "@@" [a-zA-Z_] word*  { return rbs_next_token(state, tA2IDENT); }

      "$" global_ident      { return rbs_next_token(state, tGIDENT); }

      skip = ([ \t]+|[\r\n]);

      skip     { return rbs_next_token(state, tTRIVIA); }
      "\x00"   { return rbs_next_eof_token(state); }
      *        { return rbs_next_token(state, ErrorToken); }
  */
}

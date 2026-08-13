#include "rbs/lexer.h"

rbs_token_t rbs_lexer_next_token(rbs_lexer_t *lexer) {
  rbs_lexer_t backup;

  backup = *lexer;

  /*!re2c
      re2c:flags:u = 1;
      re2c:api:style = free-form;
      re2c:flags:input = custom;
      re2c:define:YYCTYPE = "unsigned int";
      re2c:define:YYPEEK = "rbs_peek(lexer)";
      re2c:define:YYSKIP = "rbs_skip(lexer);";
      re2c:define:YYBACKUP = "backup = *lexer;";
      re2c:define:YYRESTORE = "*lexer = backup;";
      re2c:yyfill:enable  = 0;

      // Ruby's rule for what an identifier is made of is `ISALNUM(c) ||
      // (c) == '_' || !ISASCII(c)`, so define the class by what it leaves
      // out: every ASCII character that is not a word character, and the
      // sentinel `rbs_next_char` reports for a byte that is invalid under
      // the active encoding. Everything else can appear in an identifier,
      // which is how a non-ASCII character gets in.
      ident_char = . \ ([\x00-\x7F] \ [a-zA-Z0-9_]) \ [\uFFFD];

      // An ASCII digit cannot lead an identifier, but a non-ASCII one can --
      // Ruby accepts a name made of full-width digits. Since `rbs_next_char`
      // never reports a non-ASCII character as `[0-9]`, subtracting the ASCII
      // digits from `ident_char` is the whole of that rule.
      ident_start = ident_char \ [0-9];

      operator = "/" | "~" | "[]=" | "!" | "!=" | "!~" | "-" | "-@" | "+" | "+@"
               | "==" | "===" | "=~" | "<<" | "<=" | "<=>" | ">" | ">=" | ">>" | "%";

      "("   { return rbs_next_token(lexer, pLPAREN); }
      ")"   { return rbs_next_token(lexer, pRPAREN); }
      "["   { return rbs_next_token(lexer, pLBRACKET); }
      "]"   { return rbs_next_token(lexer, pRBRACKET); }
      "{"   { return rbs_next_token(lexer, pLBRACE); }
      "}"   { return rbs_next_token(lexer, pRBRACE); }
      ","   { return rbs_next_token(lexer, pCOMMA); }
      "|"   { return rbs_next_token(lexer, pBAR); }
      "^"   { return rbs_next_token(lexer, pHAT); }
      "&"   { return rbs_next_token(lexer, pAMP); }
      "?"   { return rbs_next_token(lexer, pQUESTION); }
      "*"   { return rbs_next_token(lexer, pSTAR); }
      "**"  { return rbs_next_token(lexer, pSTAR2); }
      "."   { return rbs_next_token(lexer, pDOT); }
      "..." { return rbs_next_token(lexer, pDOT3); }
      "`"   {  return rbs_next_token(lexer, tOPERATOR); }
      "`"   [^ :\x00] [^`\x00]* "`" { return rbs_next_token(lexer, tQIDENT); }
      "->"  { return rbs_next_token(lexer, pARROW); }
      "=>"  { return rbs_next_token(lexer, pFATARROW); }
      "="   { return rbs_next_token(lexer, pEQ); }
      ":"   { return rbs_next_token(lexer, pCOLON); }
      "::"  { return rbs_next_token(lexer, pCOLON2); }
      "<"   { return rbs_next_token(lexer, pLT); }
      ">"   { return rbs_next_token(lexer, pGT); }
      "[]"  { return rbs_next_token(lexer, pAREF_OPR); }
      operator  { return rbs_next_token(lexer, tOPERATOR); }
      "--" [^\x00]* { return rbs_next_token(lexer, tINLINECOMMENT); }

      number = [0-9] [0-9_]*;
      ("-"|"+")? number    { return rbs_next_token(lexer, tINTEGER); }

      "%a{" [^}\x00]* "}"  { return rbs_next_token(lexer, tANNOTATION); }
      "%a(" [^)\x00]* ")"  { return rbs_next_token(lexer, tANNOTATION); }
      "%a[" [^\]\x00]* "]" { return rbs_next_token(lexer, tANNOTATION); }
      "%a|" [^|\x00]* "|"  { return rbs_next_token(lexer, tANNOTATION); }
      "%a<" [^>\x00]* ">"  { return rbs_next_token(lexer, tANNOTATION); }

      "#" (. \ [\x00\uFFFD])*    {
        // Keep a bare CR in the comment, but leave the CR in CRLF for a trivia token.
        if (rbs_peek(lexer) == '\n' && lexer->string.start[lexer->current.byte_pos - 1] == '\r') {
          lexer->current.byte_pos -= 1;
          lexer->current.char_pos -= 1;
          lexer->current.column -= 1;
          lexer->current_code_point = '\r';
          lexer->current_character_bytes = 1;
        }

        return rbs_next_token(
          lexer,
          lexer->first_token_of_line ? tLINECOMMENT : tCOMMENT
        );
      }

      "alias"         { return rbs_next_token(lexer, kALIAS); }
      "attr_accessor" { return rbs_next_token(lexer, kATTRACCESSOR); }
      "attr_reader"   { return rbs_next_token(lexer, kATTRREADER); }
      "attr_writer"   { return rbs_next_token(lexer, kATTRWRITER); }
      "bool"          { return rbs_next_token(lexer, kBOOL); }
      "bot"           { return rbs_next_token(lexer, kBOT); }
      "class"         { return rbs_next_token(lexer, kCLASS); }
      "class-alias"   { return rbs_next_token(lexer, kCLASSALIAS); }
      "def"           { return rbs_next_token(lexer, kDEF); }
      "end"           { return rbs_next_token(lexer, kEND); }
      "extend"        { return rbs_next_token(lexer, kEXTEND); }
      "false"         { return rbs_next_token(lexer, kFALSE); }
      "in"            { return rbs_next_token(lexer, kIN); }
      "include"       { return rbs_next_token(lexer, kINCLUDE); }
      "instance"      { return rbs_next_token(lexer, kINSTANCE); }
      "interface"     { return rbs_next_token(lexer, kINTERFACE); }
      "module"        { return rbs_next_token(lexer, kMODULE); }
      "module-alias"  { return rbs_next_token(lexer, kMODULEALIAS); }
      "module-self"   { return rbs_next_token(lexer, kMODULESELF); }
      "nil"           { return rbs_next_token(lexer, kNIL); }
      "out"           { return rbs_next_token(lexer, kOUT); }
      "prepend"       { return rbs_next_token(lexer, kPREPEND); }
      "private"       { return rbs_next_token(lexer, kPRIVATE); }
      "public"        { return rbs_next_token(lexer, kPUBLIC); }
      "self"          { return rbs_next_token(lexer, kSELF); }
      "singleton"     { return rbs_next_token(lexer, kSINGLETON); }
      "top"           { return rbs_next_token(lexer, kTOP); }
      "true"          { return rbs_next_token(lexer, kTRUE); }
      "type"          { return rbs_next_token(lexer, kTYPE); }
      "unchecked"     { return rbs_next_token(lexer, kUNCHECKED); }
      "untyped"       { return rbs_next_token(lexer, kUNTYPED); }
      "void"          { return rbs_next_token(lexer, kVOID); }
      "use"           { return rbs_next_token(lexer, kUSE); }
      "as"            { return rbs_next_token(lexer, kAS); }
      "__todo__"      { return rbs_next_token(lexer, k__TODO__); }
      "@rbs"          { return rbs_next_token(lexer, kATRBS); }
      "skip"          { return rbs_next_token(lexer, kSKIP); }
      "return"        { return rbs_next_token(lexer, kRETURN); }

      unicode_char = "\\u" [0-9a-fA-F]{4};
      oct_char = "\\x" [0-9a-f]{1,2};
      hex_char = "\\" [0-7]{1,3};

      dqstring = ["] (unicode_char | oct_char | hex_char | "\\" [^xu] | [^\\"\x00])* ["];
      sqstring = ['] ("\\"['\\] | [^'\x00])* ['];

      dqstring     { return rbs_next_token(lexer, tDQSTRING); }
      sqstring     { return rbs_next_token(lexer, tSQSTRING); }
      ":" dqstring { return rbs_next_token(lexer, tDQSYMBOL); }
      ":" sqstring { return rbs_next_token(lexer, tSQSYMBOL); }

      symbol_opr = ":|" | ":&" | ":/" | ":%" | ":~" | ":`" | ":^"
                 | ":==" | ":=~" | ":===" | ":!" | ":!=" | ":!~"
                 | ":<" | ":<=" | ":<<" | ":<=>" | ":>" | ":>=" | ":>>"
                 | ":-" | ":-@" | ":+" | ":+@" | ":*" | ":**" | ":[]" | ":[]=";

      global_ident = [0-9]+
                   | "-" [a-zA-Z0-9_]
                   | [~*$?!@\\/;,.=:<>"&'`+]
                   | [^ \t\r\n:;=.,!"$%&()-+~|\\'[\]{}*/<>^\x00]+;

      ":" "@"{0,2} ident_start ident_char* [!?=]?  { return rbs_next_token(lexer, tSYMBOL); }
      ":$" global_ident                            { return rbs_next_token(lexer, tSYMBOL); }
      symbol_opr                                   { return rbs_next_token(lexer, tSYMBOL); }

      [a-z] ident_char*          { return rbs_next_token(lexer, tLIDENT); }
      [A-Z] ident_char*          { return rbs_next_token(lexer, tUIDENT); }
      "_" [a-z0-9_] ident_char*  { return rbs_next_token(lexer, tULLIDENT); }
      "_" [A-Z] ident_char*      { return rbs_next_token(lexer, tULIDENT); }
      "_"                        { return rbs_next_token(lexer, tULLIDENT); }

      // Every ASCII spelling is covered by one of the rules above, which match
      // exactly as far, and re2c settles a tie of equal length in favour of the
      // rule written first. So this one is left with the names that open with a
      // character outside ASCII.
      //
      // RBS reads the case of that character to tell a class name from an alias
      // name, and outside ASCII there is no reading of it that both the lexer
      // and `TypeName#kind` can agree on. Those names get a token of their own
      // and the parser takes it only where the question does not come up.
      ident_start ident_char* { return rbs_next_token(lexer, tNONASCIIIDENT); }

      // None of these four needs to know the case of the first character, so
      // widening the leading position to `ident_start` is all they need.
      ident_start ident_char* "!"  { return rbs_next_token(lexer, tBANGIDENT); }
      ident_start ident_char* "="  { return rbs_next_token(lexer, tEQIDENT); }

      "@" ident_start ident_char*  { return rbs_next_token(lexer, tAIDENT); }
      "@@" ident_start ident_char* { return rbs_next_token(lexer, tA2IDENT); }

      "$" global_ident      { return rbs_next_token(lexer, tGIDENT); }

      skip = ([ \t]+|[\r\n]);

      skip     { return rbs_next_token(lexer, tTRIVIA); }
      "\x00"   { return rbs_next_eof_token(lexer); }
      *        { return rbs_next_token(lexer, ErrorToken); }
  */
}

#ifndef RBS__LEXER_H
#define RBS__LEXER_H

#include "rbs_string.h"
#include "rbs_encoding.h"

enum RBSTokenType {
  NullType,         /* (Nothing) */
  pEOF,             /* EOF */
  ErrorToken,       /* Error */

  pLPAREN,          /* ( */
  pRPAREN,          /* ) */
  pCOLON,           /* : */
  pCOLON2,          /* :: */
  pLBRACKET,        /* [ */
  pRBRACKET,        /* ] */
  pLBRACE,          /* { */
  pRBRACE,          /* } */
  pHAT,             /* ^ */
  pARROW,           /* -> */
  pFATARROW,        /* => */
  pCOMMA,           /* , */
  pBAR,             /* | */
  pAMP,             /* & */
  pSTAR,            /* * */
  pSTAR2,           /* ** */
  pDOT,             /* . */
  pDOT3,            /* ... */
  pBANG,            /* ! */
  pQUESTION,        /* ? */
  pLT,              /* < */
  pEQ,              /* = */

  kALIAS,           /* alias */
  kATTRACCESSOR,    /* attr_accessor */
  kATTRREADER,      /* attr_reader */
  kATTRWRITER,      /* attr_writer */
  kBOOL,            /* bool */
  kBOT,             /* bot */
  kCLASS,           /* class */
  kDEF,             /* def */
  kEND,             /* end */
  kEXTEND,          /* extend */
  kFALSE,           /* false */
  kIN,              /* in */
  kINCLUDE,         /* include */
  kINSTANCE,        /* instance */
  kINTERFACE,       /* interface */
  kMODULE,          /* module */
  kNIL,             /* nil */
  kOUT,             /* out */
  kPREPEND,         /* prepend */
  kPRIVATE,         /* private */
  kPUBLIC,          /* public */
  kSELF,            /* self */
  kSINGLETON,       /* singleton */
  kTOP,             /* top */
  kTRUE,            /* true */
  kTYPE,            /* type */
  kUNCHECKED,       /* unchecked */
  kUNTYPED,         /* untyped */
  kVOID,            /* void */
  kUSE,             /* use */
  kAS,              /* as */
  k__TODO__,        /* __todo__ */

  tLIDENT,          /* Identifiers starting with lower case */
  tUIDENT,          /* Identifiers starting with upper case */
  tULIDENT,         /* Identifiers starting with `_` followed by upper case */
  tULLIDENT,        /* Identifiers starting with `_` followed by lower case */
  tGIDENT,          /* Identifiers starting with `$` */
  tAIDENT,          /* Identifiers starting with `@` */
  tA2IDENT,         /* Identifiers starting with `@@` */
  tBANGIDENT,       /* Identifiers ending with `!` */
  tEQIDENT,         /* Identifiers ending with `=` */
  tQIDENT,          /* Quoted identifier */
  pAREF_OPR,        /* [] */
  tOPERATOR,        /* Operator identifier */

  tCOMMENT,         /* Comment */
  tLINECOMMENT,     /* Comment of all line */

  tTRIVIA,          /* Trivia tokens -- space and new line */

  tDQSTRING,        /* Double quoted string */
  tSQSTRING,        /* Single quoted string */
  tINTEGER,         /* Integer */
  tSYMBOL,          /* Symbol */
  tDQSYMBOL,        /* Double quoted symbol */
  tSQSYMBOL,        /* Single quoted symbol */
  tANNOTATION,      /* Annotation */
};

/**
 * The `byte_pos` (or `char_pos`) is the primary data.
 * The rest are cache.
 *
 * They can be computed from `byte_pos` (or `char_pos`), but it needs full scan from the beginning of the string (depending on the encoding).
 * */
typedef struct {
  int byte_pos;
  int char_pos;
  int line;
  int column;
} position;

typedef struct {
  position start;
  position end;
} range;

typedef struct {
  enum RBSTokenType type;
  range range;
} token;

/**
 * The lexer state is the curren token.
 *
 * ```
 * ... "a string token"
 *    ^                      start position
 *          ^                current position
 *     ~~~~~~                Token => "a str
 * ```
 * */
typedef struct {
  rbs_string_t string;
  int start_pos;                  /* The character position that defines the start of the input */
  int end_pos;                    /* The character position that defines the end of the input */
  position current;               /* The current position */
  position start;                 /* The start position of the current token */
  bool first_token_of_line;       /* This flag is used for tLINECOMMENT */
  unsigned int last_char;         /* Last peeked character */
  const rbs_encoding_t *encoding;
} lexstate;

extern token NullToken;
extern position NullPosition;
extern range NULL_RANGE;

char *rbs_peek_token(lexstate *state, token tok);
int rbs_token_chars(token tok);
int rbs_token_bytes(token tok);

#define rbs_null_position_p(pos) (pos.byte_pos == -1)
#define rbs_null_range_p(range) (range.start.byte_pos == -1)
#define rbs_nonnull_pos_or(pos1, pos2) (rbs_null_position_p(pos1) ? pos2 : pos1)
#define RBS_RANGE_BYTES(range) (range.end.byte_pos - range.start.byte_pos)

const char *token_type_str(enum RBSTokenType type);

/**
 * Read next character.
 * */
unsigned int rbs_peek(lexstate *state);

/**
 * Skip one character.
 * */
void rbs_skip(lexstate *state);

/**
 * Skip n characters.
 * */
void rbs_skipn(lexstate *state, size_t size);

/**
 * Return new token with given type.
 * */
token rbs_next_token(lexstate *state, enum RBSTokenType type);

/**
 * Return new token with EOF type.
 * */
token rbs_next_eof_token(lexstate *state);

token rbsparser_next_token(lexstate *state);

void rbs_print_token(token tok);

#endif

/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* NOLINTNEXTLINE(modernize-use-using) */
typedef enum cmListFileLexer_Type_e
{
  cmListFileLexer_Token_None,
  cmListFileLexer_Token_Space,
  cmListFileLexer_Token_Newline,
  cmListFileLexer_Token_Identifier,
  cmListFileLexer_Token_ParenLeft,
  cmListFileLexer_Token_ParenRight,
  cmListFileLexer_Token_ArgumentUnquoted,
  cmListFileLexer_Token_ArgumentQuoted,
  cmListFileLexer_Token_ArgumentBracket,
  cmListFileLexer_Token_CommentBracket,
  cmListFileLexer_Token_BadCharacter,
  cmListFileLexer_Token_BadBracket,
  cmListFileLexer_Token_BadString
} cmListFileLexer_Type;

/* NOLINTNEXTLINE(modernize-use-using) */
typedef struct cmListFileLexer_Token_s cmListFileLexer_Token;
struct cmListFileLexer_Token_s
{
  cmListFileLexer_Type type;
  char* text;
  int length;
  int line;
  int column;
};

enum cmListFileLexer_BOM_e
{
  cmListFileLexer_BOM_None,
  cmListFileLexer_BOM_Broken,
  cmListFileLexer_BOM_UTF8,
  cmListFileLexer_BOM_UTF16BE,
  cmListFileLexer_BOM_UTF16LE,
  cmListFileLexer_BOM_UTF32BE,
  cmListFileLexer_BOM_UTF32LE
};

/* NOLINTNEXTLINE(modernize-use-using) */
typedef enum cmListFileLexer_BOM_e cmListFileLexer_BOM;

/* NOLINTNEXTLINE(modernize-use-using) */
typedef struct cmListFileLexer_s cmListFileLexer;

cmListFileLexer* cmListFileLexer_New(void);
int cmListFileLexer_SetFileName(cmListFileLexer*, char const*,
                                cmListFileLexer_BOM* bom);
int cmListFileLexer_SetString(cmListFileLexer*, char const*);
cmListFileLexer_Token* cmListFileLexer_Scan(cmListFileLexer*);
long cmListFileLexer_GetCurrentLine(cmListFileLexer*);
long cmListFileLexer_GetCurrentColumn(cmListFileLexer*);
char const* cmListFileLexer_GetTypeAsString(cmListFileLexer*,
                                            cmListFileLexer_Type);
void cmListFileLexer_Delete(cmListFileLexer*);

#ifdef __cplusplus
} /* extern "C" */
#endif

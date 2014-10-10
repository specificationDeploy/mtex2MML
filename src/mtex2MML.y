%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "mtex2MML.h"
#include "parse_extras.h"

#include "../deps/uthash/uthash.h"

struct css_colors *colors = NULL;

#define YYSTYPE char *
#define YYPARSE_PARAM_TYPE char **
#define YYPARSE_PARAM ret_str

// #define YYDEBUG 1
// yydebug = 1;

#define yytext mtex2MML_yytext

 extern int yylex ();

 extern char * yytext;

 static void mtex2MML_default_error (const char * msg)
   {
     if (msg)
       fprintf(stderr, "Line: %d Error: %s\n", mtex2MML_lineno, msg);
   }

 void (*mtex2MML_error) (const char * msg) = mtex2MML_default_error;

 static void yyerror (char * s)
   {
     char * msg = mtex2MML_copy3 (s, " at token ", yytext);
     if (mtex2MML_error)
       (*mtex2MML_error) (msg);
     mtex2MML_free_string (msg);
   }

 /* Note: If length is 0, then buffer is treated like a string; otherwise only length bytes are written.
  */
 static void mtex2MML_default_write (const char * buffer, unsigned long length)
   {
     if (buffer)
       {
	 if (length)
	   fwrite (buffer, 1, length, stdout);
	 else
	   fputs (buffer, stdout);
       }
   }

 static void mtex2MML_default_write_mathml (const char * mathml)
   {
     if (mtex2MML_write)
       (*mtex2MML_write) (mathml, 0);
   }

#ifdef mtex2MML_CAPTURE
    static char * mtex2MML_output_string = "" ;

    const char * mtex2MML_output ()
    {
        char * copy = (char *) malloc((mtex2MML_output_string ? strlen(mtex2MML_output_string) : 0) + 1);
        if (copy)
          {
           if (mtex2MML_output_string)
             {
               strcpy(copy, mtex2MML_output_string);
               if (*mtex2MML_output_string != '\0')
                   free(mtex2MML_output_string);
             }
           else
             copy[0] = 0;
           mtex2MML_output_string = "";
          }
        return copy;
    }

 static void mtex2MML_capture (const char * buffer, unsigned long length)
    {
     if (buffer)
       {
         if (length)
           {
              unsigned long first_length = mtex2MML_output_string ? strlen(mtex2MML_output_string) : 0;
              char * copy  = (char *) malloc(first_length + length + 1);
              if (copy)
                {
                  if (mtex2MML_output_string)
                    {
                       strcpy(copy, mtex2MML_output_string);
                       if (*mtex2MML_output_string != '\0')
                          free(mtex2MML_output_string);
                    }
                  else
                     copy[0] = 0;
                  strncat(copy, buffer, length);
                  mtex2MML_output_string = copy;
                 }
            }
         else
            {
              char * copy = mtex2MML_copy2(mtex2MML_output_string, buffer);
              if (*mtex2MML_output_string != '\0')
                 free(mtex2MML_output_string);
              mtex2MML_output_string = copy;
            }
        }
    }

    static void mtex2MML_capture_mathml (const char * buffer)
    {
       char * temp = mtex2MML_copy2(mtex2MML_output_string, buffer);
       if (*mtex2MML_output_string != '\0')
         free(mtex2MML_output_string);
       mtex2MML_output_string = temp;
    }
    void (*mtex2MML_write) (const char * buffer, unsigned long length) = mtex2MML_capture;
    void (*mtex2MML_write_mathml) (const char * mathml) = mtex2MML_capture_mathml;
#else
    void (*mtex2MML_write) (const char * buffer, unsigned long length) = mtex2MML_default_write;
    void (*mtex2MML_write_mathml) (const char * mathml) = mtex2MML_default_write_mathml;
#endif

 char * mtex2MML_empty_string = "";

 /* Create a copy of a string, adding space for extra chars
  */
 char * mtex2MML_copy_string_extra (const char * str, unsigned extra)
   {
     char * copy = (char *) malloc(extra + (str ? strlen (str) : 0) + 1);
     if (copy)
       {
	 if (str)
	   strcpy(copy, str);
	 else
	   copy[0] = 0;
       }
     return copy ? copy : mtex2MML_empty_string;
   }

 /* Create a copy of a string, appending two strings
  */
 char * mtex2MML_copy3 (const char * first, const char * second, const char * third)
   {
     int  first_length =  first ? strlen( first) : 0;
     int second_length = second ? strlen(second) : 0;
     int  third_length =  third ? strlen( third) : 0;

     char * copy = (char *) malloc(first_length + second_length + third_length + 1);

     if (copy)
       {
	 if (first)
	   strcpy(copy, first);
	 else
	   copy[0] = 0;

	 if (second) strcat(copy, second);
	 if ( third) strcat(copy,  third);
       }
     return copy ? copy : mtex2MML_empty_string;
   }

 /* Create a copy of a string, appending a second string
  */
 char * mtex2MML_copy2 (const char * first, const char * second)
   {
     return mtex2MML_copy3(first, second, 0);
   }

 /* Create a copy of a string
  */
 char * mtex2MML_copy_string (const char * str)
   {
     return mtex2MML_copy3(str, 0, 0);
   }

 /* Create a copy of a string, escaping unsafe characters for XML
  */
 char * mtex2MML_copy_escaped (const char * str)
   {
     unsigned long length = 0;

     const char * ptr1 = str;

     char * ptr2 = 0;
     char * copy = 0;

     if ( str == 0) return mtex2MML_empty_string;
     if (*str == 0) return mtex2MML_empty_string;

     while (*ptr1)
       {
	 switch (*ptr1)
	   {
	   case '<':  /* &lt;   */
	   case '>':  /* &gt;   */
	     length += 4;
	     break;
	   case '&':  /* &amp;  */
	     length += 5;
	     break;
	   case '\'': /* &apos; */
	   case '"':  /* &quot; */
	   case '-':  /* &#x2d; */
	     length += 6;
	     break;
	   default:
	     length += 1;
	     break;
	   }
	 ++ptr1;
       }

     copy = (char *) malloc (length + 1);

     if (copy)
       {
	 ptr1 = str;
	 ptr2 = copy;

	 while (*ptr1)
	   {
	     switch (*ptr1)
	       {
	       case '<':
		 strcpy (ptr2, "&lt;");
		 ptr2 += 4;
		 break;
	       case '>':
		 strcpy (ptr2, "&gt;");
		 ptr2 += 4;
		 break;
	       case '&':  /* &amp;  */
		 strcpy (ptr2, "&amp;");
		 ptr2 += 5;
		 break;
	       case '\'': /* &apos; */
		 strcpy (ptr2, "&apos;");
		 ptr2 += 6;
		 break;
	       case '"':  /* &quot; */
		 strcpy (ptr2, "&quot;");
		 ptr2 += 6;
		 break;
	       case '-':  /* &#x2d; */
		 strcpy (ptr2, "&#x2d;");
		 ptr2 += 6;
		 break;
	       default:
		 *ptr2++ = *ptr1;
		 break;
	       }
	     ++ptr1;
	   }
	 *ptr2 = 0;
       }
     return copy ? copy : mtex2MML_empty_string;
   }

 /* Create a hex character reference string corresponding to code
  */
 char * mtex2MML_character_reference (unsigned long int code)
   {
#define ENTITY_LENGTH 10
     char * entity = (char *) malloc(ENTITY_LENGTH);
     sprintf(entity, "&#x%05lx;", code);
     return entity;
   }

 void mtex2MML_free_string (char * str)
   {
     if (str && str != mtex2MML_empty_string)
       free(str);
   }

%}

%left TEXOVER TEXATOP
%token CHAR STARTMATH STARTDMATH ENDMATH MI MIB MN MO SUP SUB MROWOPEN MROWCLOSE LEFT RIGHT BIG BBIG BIGG BBIGG BIGL BBIGL BIGGL BBIGGL FRAC TFRAC OPERATORNAME MATHOP MATHBIN MATHREL MOP MOL MOLL MOF MOR PERIODDELIM OTHERDELIM LEFTDELIM RIGHTDELIM MOS MOB SQRT ROOT BINOM TBINOM UNDER OVER OVERBRACE OVERBRACKET UNDERLINE UNDERBRACE UNDERBRACKET UNDEROVER TENSOR MULTI ARRAYALIGN ROWSPACINGDEF ROWLINESDEF COLUMNALIGN ARRAY COLSEP ROWSEP ARRAYOPTS COLLAYOUT COLALIGN ROWALIGN ALIGN EQROWS EQCOLS ROWLINES COLLINES FRAME PADDING ATTRLIST ITALICS SANS TT BOLD BOXED SLASHED RM BB ST END BBLOWERCHAR BBUPPERCHAR BBDIGIT CALCHAR FRAKCHAR CAL FRAK CLAP LLAP RLAP ROWOPTS TEXTSIZE SCSIZE SCSCSIZE DISPLAY TEXTSTY TEXTBOX TEXTSTRING ACUTE GRAVE BREVE MATHRING XMLSTRING CELLOPTS ROWSPAN COLSPAN THINSPACE MEDSPACE THICKSPACE QUAD QQUAD NEGSPACE NEGMEDSPACE NEGTHICKSPACE PHANTOM HREF UNKNOWNCHAR EMPTYMROW STATLINE TOOLTIP TOGGLE TOGGLESTART TOGGLEEND FGHIGHLIGHT BGHIGHLIGHT COLORBOX SPACE INTONE INTTWO INTTHREE OVERLEFTARROW OVERLEFTRIGHTARROW OVERRIGHTARROW UNDERLEFTARROW UNDERLEFTRIGHTARROW UNDERRIGHTARROW BAR WIDEBAR VEC WIDEVEC HAT WIDEHAT CHECK WIDECHECK TILDE WIDETILDE DOT DDOT DDDOT DDDDOT UNARYMINUS UNARYPLUS BEGINENV ENDENV MATRIX PMATRIX BMATRIX BBMATRIX VMATRIX VVMATRIX SVG ENDSVG SMALLMATRIX CASES ALIGNED GATHERED SUBSTACK PMOD RMCHAR COLOR BGCOLOR XARROW OPTARGOPEN OPTARGCLOSE MTEXNUM RAISEBOX NEG

%%

doc:  xmlmmlTermList {/* all processing done in body*/};

xmlmmlTermList:
{/* nothing - do nothing*/}
| char {/* proc done in body*/}
| expression {/* all proc. in body*/}
| xmlmmlTermList char {/* all proc. in body*/}
| xmlmmlTermList expression {/* all proc. in body*/};

char: CHAR { /* Do nothing...but what did this used to do? printf("%s", $1); */ };

expression: STARTMATH ENDMATH {/* empty math group - ignore*/}
| STARTDMATH ENDMATH {/* ditto */}
| STARTMATH compoundTermList ENDMATH {
  char ** r = (char **) ret_str;
  char * p = mtex2MML_copy3("<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow>", $2, "</mrow><annotation encoding='application/x-tex'>");
  char * s = mtex2MML_copy3(p, $3, "</annotation></semantics></math>");
  mtex2MML_free_string(p);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
  if (r) {
    (*r) = (s == mtex2MML_empty_string) ? 0 : s;
  }
  else {
    if (mtex2MML_write_mathml)
      (*mtex2MML_write_mathml) (s);
    mtex2MML_free_string(s);
  }
}
| STARTDMATH compoundTermList ENDMATH {
  char ** r = (char **) ret_str;
  char * p = mtex2MML_copy3("<math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><semantics><mrow>", $2, "</mrow><annotation encoding='application/x-tex'>");
  char * s = mtex2MML_copy3(p, $3, "</annotation></semantics></math>");
  mtex2MML_free_string(p);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
  if (r) {
    (*r) = (s == mtex2MML_empty_string) ? 0 : s;
  }
  else {
    if (mtex2MML_write_mathml)
      (*mtex2MML_write_mathml) (s);
    mtex2MML_free_string(s);
  }
};

compoundTermList: compoundTerm {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| compoundTermList compoundTerm {
  $$ = mtex2MML_copy2($1, $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

compoundTerm: mob SUB closedTerm SUP closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munderover>", $1, " ");
    char * s2 = mtex2MML_copy3($3, " ", $5);
    $$ = mtex2MML_copy3(s1, s2, "</munderover>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  else {
    char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
    char * s2 = mtex2MML_copy3($3, " ", $5);
    $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| mob SUB closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munder>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</munder>");
    mtex2MML_free_string(s1);
  }
  else {
    char * s1 = mtex2MML_copy3("<msub>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</msub>");
    mtex2MML_free_string(s1);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| mob SUP closedTerm SUB closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munderover>", $1, " ");
    char * s2 = mtex2MML_copy3($5, " ", $3);
    $$ = mtex2MML_copy3(s1, s2, "</munderover>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  else {
    char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
    char * s2 = mtex2MML_copy3($5, " ", $3);
    $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| mob SUP closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<mover>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</mover>");
    mtex2MML_free_string(s1);
  }
  else {
    char * s1 = mtex2MML_copy3("<msup>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</msup>");
    mtex2MML_free_string(s1);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
|mib SUB closedTerm SUP closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munderover>", $1, " ");
    char * s2 = mtex2MML_copy3($3, " ", $5);
    $$ = mtex2MML_copy3(s1, s2, "</munderover>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  else {
    char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
    char * s2 = mtex2MML_copy3($3, " ", $5);
    $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| mib SUB closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munder>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</munder>");
    mtex2MML_free_string(s1);
  }
  else {
    char * s1 = mtex2MML_copy3("<msub>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</msub>");
    mtex2MML_free_string(s1);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| mib SUP closedTerm SUB closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<munderover>", $1, " ");
    char * s2 = mtex2MML_copy3($5, " ", $3);
    $$ = mtex2MML_copy3(s1, s2, "</munderover>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  else {
    char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
    char * s2 = mtex2MML_copy3($5, " ", $3);
    $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
    mtex2MML_free_string(s1);
    mtex2MML_free_string(s2);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| mib SUP closedTerm {
  if (mtex2MML_displaymode == 1) {
    char * s1 = mtex2MML_copy3("<mover>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</mover>");
    mtex2MML_free_string(s1);
  }
  else {
    char * s1 = mtex2MML_copy3("<msup>", $1, " ");
    $$ = mtex2MML_copy3(s1, $3, "</msup>");
    mtex2MML_free_string(s1);
  }
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| closedTerm SUB closedTerm SUP closedTerm {
  char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
  char * s2 = mtex2MML_copy3($3, " ", $5);
  $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| closedTerm SUP closedTerm SUB closedTerm {
  char * s1 = mtex2MML_copy3("<msubsup>", $1, " ");
  char * s2 = mtex2MML_copy3($5, " ", $3);
  $$ = mtex2MML_copy3(s1, s2, "</msubsup>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| closedTerm SUB closedTerm {
  char * s1 = mtex2MML_copy3("<msub>", $1, " ");
  $$ = mtex2MML_copy3(s1, $3, "</msub>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| closedTerm SUP closedTerm {
  char * s1 = mtex2MML_copy3("<msup>", $1, " ");
  $$ = mtex2MML_copy3(s1, $3, "</msup>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| SUB closedTerm {
  $$ = mtex2MML_copy3("<msub><mo/>", $2, "</msub>");
  mtex2MML_free_string($2);
}
| SUP closedTerm {
  $$ = mtex2MML_copy3("<msup><mo/>", $2, "</msup>");
  mtex2MML_free_string($2);
}
| closedTerm {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

closedTerm: array
| unaryminus
| unaryplus
| mib
| mi {
  $$ = mtex2MML_copy3("<mi>", $1, "</mi>");
  mtex2MML_free_string($1);
}
| mn {
  $$ = mtex2MML_copy3("<mn>", $1, "</mn>");
  mtex2MML_free_string($1);
}
| mo
| tensor
| multi
| mfrac
| binom
| msqrt
| mroot
| raisebox
| munder
| mover
| bar
| vec
| hat
| acute
| grave
| breve
| mathring
| dot
| ddot
| dddot
| ddddot
| check
| tilde
| overleftarrow
| overleftrightarrow
| overrightarrow
| underleftarrow
| underleftrightarrow
| underrightarrow
| moverbrace
| moverbracket
| munderbrace
| munderbracket
| munderline
| munderover
| emptymrow
| mathclap
| mathllap
| mathrlap
| displaystyle
| textstyle
| textsize
| scriptsize
| scriptscriptsize
| italics
| sans
| mono
| bold
| roman
| rmchars
| bbold
| frak
| slashed
| boxed
| cal
| space
| textstring
| thinspace
| medspace
| thickspace
| quad
| qquad
| negspace
| negmedspace
| negthickspace
| phantom
| href
| statusline
| tooltip
| toggle
| fghighlight
| bghighlight
| colorbox
| color
| texover
| texatop
| MROWOPEN closedTerm MROWCLOSE {
  $$ = mtex2MML_copy_string($2);
  mtex2MML_free_string($2);
}
| MROWOPEN compoundTermList MROWCLOSE {
  $$ = mtex2MML_copy3("<mrow>", $2, "</mrow>");
  mtex2MML_free_string($2);
}
| left compoundTermList right {
  char * s1 = mtex2MML_copy3("<mrow>", $1, $2);
  $$ = mtex2MML_copy3(s1, $3, "</mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| mathenv
| substack
| pmod
| unrecognized;

left: LEFT LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo>", $2, "</mo>");
  mtex2MML_free_string($2);
}
| LEFT OTHERDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo>", $2, "</mo>");
  mtex2MML_free_string($2);
}
| LEFT PERIODDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy_string("");
  mtex2MML_free_string($2);
};

right: RIGHT RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo>", $2, "</mo>");
  mtex2MML_free_string($2);
}
| RIGHT OTHERDELIM {
  $$ = mtex2MML_copy3("<mo>", $2, "</mo>");
  mtex2MML_free_string($2);
}
| RIGHT PERIODDELIM {
  $$ = mtex2MML_copy_string("");
  mtex2MML_free_string($2);
};

bigdelim: BIG LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIG RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIG OTHERDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIG LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIG RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIG OTHERDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGG LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGG RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGG OTHERDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGG LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGG RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGG OTHERDELIM {
  $$ = mtex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
|BIGL LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGL OTHERDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGL LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGL OTHERDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGGL LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BIGGL OTHERDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGGL LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| BBIGGL OTHERDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", $2, "</mo>");
  mtex2MML_free_string($2);
};

unrecognized: UNKNOWNCHAR {
  $$ = mtex2MML_copy_string("<merror><mtext>Unknown character</mtext></merror>");
};

unaryminus: UNARYMINUS {
  $$ = mtex2MML_copy_string("<mo lspace=\"verythinmathspace\" rspace=\"0em\">&minus;</mo>");
};

unaryplus: UNARYPLUS {
  $$ = mtex2MML_copy_string("<mo lspace=\"verythinmathspace\" rspace=\"0em\">+</mo>");
};

mi: MI;

mib: MIB {
  mtex2MML_rowposn=2;
  $$ = mtex2MML_copy3("<mi>", $1, "</mi>");
  mtex2MML_free_string($1);
};

mn: MN
| MTEXNUM TEXTSTRING {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy_string($2);
  mtex2MML_free_string($2);
};

mob: MOB {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"thinmathspace\" rspace=\"thinmathspace\">", $1, "</mo>");
  mtex2MML_free_string($1);
};

mo: mob
| bigdelim
| MO {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo>", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOL {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo>", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOLL {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mstyle scriptlevel=\"0\"><mo>", $1, "</mo></mstyle>");
  mtex2MML_free_string($1);
}
| RIGHTDELIM {
  $$ = mtex2MML_copy3("<mo stretchy=\"false\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| LEFTDELIM {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo stretchy=\"false\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| OTHERDELIM {
  $$ = mtex2MML_copy3("<mo stretchy=\"false\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOF {
  $$ = mtex2MML_copy3("<mo stretchy=\"false\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| PERIODDELIM {
  $$ = mtex2MML_copy3("<mo>", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOS {
  mtex2MML_rowposn=2;
  $$ = mtex2MML_copy3("<mo lspace=\"mediummathspace\" rspace=\"mediummathspace\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOP {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"0em\" rspace=\"thinmathspace\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| MOR {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"verythinmathspace\">", $1, "</mo>");
  mtex2MML_free_string($1);
}
| OPERATORNAME TEXTSTRING {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"0em\" rspace=\"thinmathspace\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| MATHOP TEXTSTRING {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"thinmathspace\" rspace=\"thinmathspace\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| MATHBIN TEXTSTRING {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"mediummathspace\" rspace=\"mediummathspace\">", $2, "</mo>");
  mtex2MML_free_string($2);
}
| MATHREL TEXTSTRING {
  mtex2MML_rowposn = 2;
  $$ = mtex2MML_copy3("<mo lspace=\"thickmathspace\" rspace=\"thickmathspace\">", $2, "</mo>");
  mtex2MML_free_string($2);
};

space: SPACE ST INTONE END ST INTTWO END ST INTTHREE END {
  char * s1 = mtex2MML_copy3("<mspace height=\"", $3, "ex\" depth=\"");
  char * s2 = mtex2MML_copy3($6, "ex\" width=\"", $9);
  $$ = mtex2MML_copy3(s1, s2, "em\"/>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($6);
  mtex2MML_free_string($9);
};

statusline: STATLINE TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<maction actiontype=\"statusline\">", $3, "<mtext>");
  $$ = mtex2MML_copy3(s1, $2, "</mtext></maction>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

tooltip: TOOLTIP TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<maction actiontype=\"tooltip\">", $3, "<mtext>");
  $$ = mtex2MML_copy3(s1, $2, "</mtext></maction>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

toggle: TOGGLE closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<maction actiontype=\"toggle\" selection=\"2\">", $2, " ");
  $$ = mtex2MML_copy3(s1, $3, "</maction>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| TOGGLESTART compoundTermList TOGGLEEND {
  $$ = mtex2MML_copy3("<maction actiontype=\"toggle\">", $2, "</maction>");
  mtex2MML_free_string($2);
};

fghighlight: FGHIGHLIGHT ATTRLIST closedTerm {
  char * s1 = mtex2MML_copy3("<maction actiontype=\"highlight\" other='color=", $2, "'>");
  $$ = mtex2MML_copy3(s1, $3, "</maction>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

bghighlight: BGHIGHLIGHT ATTRLIST closedTerm {
  char * s1 = mtex2MML_copy3("<maction actiontype=\"highlight\" other='background=", $2, "'>");
  $$ = mtex2MML_copy3(s1, $3, "</maction>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

colorbox: COLORBOX ATTRLIST closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded width=\"+10px\" height=\"+5px\" depth=\"+5px\" lspace=\"5px\" mathbackground=", $2, ">");
  $$ = mtex2MML_copy3(s1, $3, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

color: COLOR ATTRLIST compoundTermList {
  char * s1;
  struct css_colors *c = NULL;

  HASH_FIND_STR( colors, $2, c );

  if (HASH_COUNT(c) > 0)
    s1 = mtex2MML_copy3("<mstyle mathcolor=", c->color, ">");
  else
    s1 = mtex2MML_copy3("<mstyle mathcolor=", $2, ">");

  $$ = mtex2MML_copy3(s1, $3, "</mstyle>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| BGCOLOR ATTRLIST compoundTermList {
  char * s1 = mtex2MML_copy3("<mstyle mathbackground=", $2, ">");
  $$ = mtex2MML_copy3(s1, $3, "</mstyle>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

mathrlap: RLAP closedTerm {
  $$ = mtex2MML_copy3("<mpadded width=\"0\">", $2, "</mpadded>");
  mtex2MML_free_string($2);
};

mathllap: LLAP closedTerm {
  $$ = mtex2MML_copy3("<mpadded width=\"0\" lspace=\"-100%width\">", $2, "</mpadded>");
  mtex2MML_free_string($2);
};

mathclap: CLAP closedTerm {
  $$ = mtex2MML_copy3("<mpadded width=\"0\" lspace=\"-50%width\">", $2, "</mpadded>");
  mtex2MML_free_string($2);
};

textstring: TEXTBOX TEXTSTRING {
  $$ = mtex2MML_copy3("<mtext>", $2, "</mtext>");
  mtex2MML_free_string($2);
};

displaystyle: DISPLAY compoundTermList {
  $$ = mtex2MML_copy3("<mstyle displaystyle=\"true\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

textstyle: TEXTSTY compoundTermList {
  $$ = mtex2MML_copy3("<mstyle displaystyle=\"false\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

textsize: TEXTSIZE compoundTermList {
  $$ = mtex2MML_copy3("<mstyle scriptlevel=\"0\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

scriptsize: SCSIZE compoundTermList {
  $$ = mtex2MML_copy3("<mstyle scriptlevel=\"1\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

scriptscriptsize: SCSCSIZE compoundTermList {
  $$ = mtex2MML_copy3("<mstyle scriptlevel=\"2\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

italics: ITALICS closedTerm {
  $$ = mtex2MML_copy3("<mstyle mathvariant=\"italic\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

sans: SANS closedTerm {
  $$ = mtex2MML_copy3("<mstyle mathvariant=\"sans-serif\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

mono: TT closedTerm {
  $$ = mtex2MML_copy3("<mstyle mathvariant=\"monospace\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

slashed: SLASHED closedTerm {
  $$ = mtex2MML_copy3("<menclose notation=\"updiagonalstrike\">", $2, "</menclose>");
  mtex2MML_free_string($2);
};

boxed: BOXED closedTerm {
  $$ = mtex2MML_copy3("<menclose notation=\"box\">", $2, "</menclose>");
  mtex2MML_free_string($2);
};

bold: BOLD closedTerm {
  $$ = mtex2MML_copy3("<mstyle mathvariant=\"bold\">", $2, "</mstyle>");
  mtex2MML_free_string($2);
};

roman: RM ST rmchars END {
  $$ = mtex2MML_copy3("<mi mathvariant=\"normal\">", $3, "</mi>");
  mtex2MML_free_string($3);
};

rmchars: RMCHAR {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rmchars RMCHAR {
  $$ = mtex2MML_copy2($1, $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

bbold: BB ST bbchars END {
  $$ = mtex2MML_copy3("<mi>", $3, "</mi>");
  mtex2MML_free_string($3);
};

bbchars: bbchar {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| bbchars bbchar {
  $$ = mtex2MML_copy2($1, $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

bbchar: BBLOWERCHAR {
  $$ = mtex2MML_copy3("&", $1, "opf;");
  mtex2MML_free_string($1);
}
| BBUPPERCHAR {
  $$ = mtex2MML_copy3("&", $1, "opf;");
  mtex2MML_free_string($1);
}
| BBDIGIT {
  /* Blackboard digits 0-9 correspond to Unicode characters 0x1D7D8-0x1D7E1 */
  char * end = $1 + 1;
  int code = 0x1D7D8 + strtoul($1, &end, 10);
  $$ = mtex2MML_character_reference(code);
  mtex2MML_free_string($1);
};

frak: FRAK ST frakletters END {
  $$ = mtex2MML_copy3("<mi>", $3, "</mi>");
  mtex2MML_free_string($3);
};

frakletters: frakletter {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| frakletters frakletter {
  $$ = mtex2MML_copy2($1, $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

frakletter: FRAKCHAR {
  $$ = mtex2MML_copy3("&", $1, "fr;");
  mtex2MML_free_string($1);
};

cal: CAL ST calletters END {
  $$ = mtex2MML_copy3("<mi>", $3, "</mi>");
  mtex2MML_free_string($3);
};

calletters: calletter {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| calletters calletter {
  $$ = mtex2MML_copy2($1, $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

calletter: CALCHAR {
  $$ = mtex2MML_copy3("&", $1, "scr;");
  mtex2MML_free_string($1);
};

thinspace: THINSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"thinmathspace\"/>");
};

medspace: MEDSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"mediummathspace\"/>");
};

thickspace: THICKSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"thickmathspace\"/>");
};

quad: QUAD {
  $$ = mtex2MML_copy_string("<mspace width=\"1em\"/>");
};

qquad: QQUAD {
  $$ = mtex2MML_copy_string("<mspace width=\"2em\"/>");
};

negspace: NEGSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"negativethinmathspace\"/>");
};

negmedspace: NEGMEDSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"negativemediummathspace\"/>");
};

negthickspace: NEGTHICKSPACE {
  $$ = mtex2MML_copy_string("<mspace width=\"negativethickmathspace\"/>");
};

phantom: PHANTOM closedTerm {
  $$ = mtex2MML_copy3("<mphantom>", $2, "</mphantom>");
  mtex2MML_free_string($2);
};

href: HREF TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mrow href=\"", $2, "\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xlink:type=\"simple\" xlink:href=\"");
  char * s2 = mtex2MML_copy3(s1, $2, "\">");
  $$ = mtex2MML_copy3(s2, $3, "</mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

tensor: TENSOR closedTerm MROWOPEN subsupList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mmultiscripts>", $2, $4);
  $$ = mtex2MML_copy2(s1, "</mmultiscripts>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
}
| TENSOR closedTerm subsupList {
  char * s1 = mtex2MML_copy3("<mmultiscripts>", $2, $3);
  $$ = mtex2MML_copy2(s1, "</mmultiscripts>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

multi: MULTI MROWOPEN subsupList MROWCLOSE closedTerm MROWOPEN subsupList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mmultiscripts>", $5, $7);
  char * s2 = mtex2MML_copy3("<mprescripts/>", $3, "</mmultiscripts>");
  $$ = mtex2MML_copy2(s1, s2);
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
  mtex2MML_free_string($7);
}
| MULTI MROWOPEN subsupList MROWCLOSE closedTerm EMPTYMROW {
  char * s1 = mtex2MML_copy2("<mmultiscripts>", $5);
  char * s2 = mtex2MML_copy3("<mprescripts/>", $3, "</mmultiscripts>");
  $$ = mtex2MML_copy2(s1, s2);
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| MULTI EMPTYMROW closedTerm MROWOPEN subsupList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mmultiscripts>", $3, $5);
  $$ = mtex2MML_copy2(s1, "</mmultiscripts>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
};

subsupList: subsupTerm {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| subsupList subsupTerm {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

subsupTerm: SUB closedTerm SUP closedTerm {
  $$ = mtex2MML_copy3($2, " ", $4);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
}
| SUB closedTerm {
  $$ = mtex2MML_copy2($2, " <none/>");
  mtex2MML_free_string($2);
}
| SUP closedTerm {
  $$ = mtex2MML_copy2("<none/> ", $2);
  mtex2MML_free_string($2);
}
| SUB SUP closedTerm {
  $$ = mtex2MML_copy2("<none/> ", $3);
  mtex2MML_free_string($3);
};

mfrac: FRAC closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mfrac>", $2, $3);
  $$ = mtex2MML_copy2(s1, "</mfrac>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| TFRAC closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mstyle displaystyle=\"false\"><mfrac>", $2, $3);
  $$ = mtex2MML_copy2(s1, "</mfrac></mstyle>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

pmod: PMOD closedTerm {
  $$ = mtex2MML_copy3( "<mrow><mo lspace=\"mediummathspace\">(</mo><mo rspace=\"thinmathspace\">mod</mo>", $2, "<mo rspace=\"mediummathspace\">)</mo></mrow>");
  mtex2MML_free_string($2);
}

texover: MROWOPEN compoundTermList TEXOVER compoundTermList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mfrac><mrow>", $2, "</mrow><mrow>");
  $$ = mtex2MML_copy3(s1, $4, "</mrow></mfrac>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
}
| left compoundTermList TEXOVER compoundTermList right {
  char * s1 = mtex2MML_copy3("<mrow>", $1, "<mfrac><mrow>");
  char * s2 = mtex2MML_copy3($2, "</mrow><mrow>", $4);
  char * s3 = mtex2MML_copy3("</mrow></mfrac>", $5, "</mrow>");
  $$ = mtex2MML_copy3(s1, s2, s3);
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($5);
};

texatop: MROWOPEN compoundTermList TEXATOP compoundTermList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mfrac linethickness=\"0\"><mrow>", $2, "</mrow><mrow>");
  $$ = mtex2MML_copy3(s1, $4, "</mrow></mfrac>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
}
| left compoundTermList TEXATOP compoundTermList right {
  char * s1 = mtex2MML_copy3("<mrow>", $1, "<mfrac linethickness=\"0\"><mrow>");
  char * s2 = mtex2MML_copy3($2, "</mrow><mrow>", $4);
  char * s3 = mtex2MML_copy3("</mrow></mfrac>", $5, "</mrow>");
  $$ = mtex2MML_copy3(s1, s2, s3);
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($5);
};

binom: BINOM closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mrow><mo>(</mo><mfrac linethickness=\"0\">", $2, $3);
  $$ = mtex2MML_copy2(s1, "</mfrac><mo>)</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| TBINOM closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mrow><mo>(</mo><mstyle displaystyle=\"false\"><mfrac linethickness=\"0\">", $2, $3);
  $$ = mtex2MML_copy2(s1, "</mfrac></mstyle><mo>)</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

underleftarrow: UNDERLEFTARROW closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&larr;</mo></munder>");
  mtex2MML_free_string($2);
};

underleftrightarrow: UNDERLEFTRIGHTARROW closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&harr;</mo></munder>");
  mtex2MML_free_string($2);
};

underrightarrow: UNDERRIGHTARROW closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&rarr;</mo></munder>");
  mtex2MML_free_string($2);
};

munderbrace: UNDERBRACE closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&UnderBrace;</mo></munder>");
  mtex2MML_free_string($2);
};

munderbracket: UNDERBRACKET closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&#9183;</mo></munder>");
  mtex2MML_free_string($2);
};

munderline: UNDERLINE closedTerm {
  $$ = mtex2MML_copy3("<munder>", $2, "<mo>&#x00332;</mo></munder>");
  mtex2MML_free_string($2);
};

moverbrace: OVERBRACE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&OverBrace;</mo></mover>");
  mtex2MML_free_string($2);
};

moverbracket: OVERBRACKET closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&#9183;</mo></mover>");
  mtex2MML_free_string($2);
};

overleftarrow: OVERLEFTARROW closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&larr;</mo></mover>");
  mtex2MML_free_string($2);
};

overleftrightarrow: OVERLEFTRIGHTARROW closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&harr;</mo></mover>");
  mtex2MML_free_string($2);
};

overrightarrow: OVERRIGHTARROW closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&rarr;</mo></mover>");
  mtex2MML_free_string($2);
};

bar: BAR closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#x000AF;</mo></mover>");
  mtex2MML_free_string($2);
}
| WIDEBAR closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&#x000AF;</mo></mover>");
  mtex2MML_free_string($2);
};

vec: VEC closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&RightVector;</mo></mover>");
  mtex2MML_free_string($2);
}
| WIDEVEC closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&RightVector;</mo></mover>");
  mtex2MML_free_string($2);
};

acute: ACUTE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&acute;</mo></mover>");
  mtex2MML_free_string($2);
};

grave: GRAVE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#x60;</mo></mover>");
  mtex2MML_free_string($2);
};

breve: BREVE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#x2d8;</mo></mover>");
  mtex2MML_free_string($2);
};

mathring: MATHRING closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#730;</mo></mover>");
  mtex2MML_free_string($2);
};

dot: DOT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&dot;</mo></mover>");
  mtex2MML_free_string($2);
};

ddot: DDOT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&Dot;</mo></mover>");
  mtex2MML_free_string($2);
};

dddot: DDDOT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&tdot;</mo></mover>");
  mtex2MML_free_string($2);
};

ddddot: DDDDOT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&DotDot;</mo></mover>");
  mtex2MML_free_string($2);
};

tilde: TILDE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&tilde;</mo></mover>");
  mtex2MML_free_string($2);
}
| WIDETILDE closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&tilde;</mo></mover>");
  mtex2MML_free_string($2);
};

check: CHECK closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#x2c7;</mo></mover>");
  mtex2MML_free_string($2);
}
| WIDECHECK closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&#x2c7;</mo></mover>");
  mtex2MML_free_string($2);
};

hat: HAT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo stretchy=\"false\">&#x5E;</mo></mover>");
  mtex2MML_free_string($2);
}
| WIDEHAT closedTerm {
  $$ = mtex2MML_copy3("<mover>", $2, "<mo>&#x5E;</mo></mover>");
  mtex2MML_free_string($2);
};

msqrt: SQRT closedTerm {
  $$ = mtex2MML_copy3("<msqrt>", $2, "</msqrt>");
  mtex2MML_free_string($2);
};

mroot: SQRT OPTARGOPEN compoundTermList OPTARGCLOSE closedTerm {
  char * s1 = mtex2MML_copy3("<mroot>", $5, $3);
  $$ = mtex2MML_copy2(s1, "</mroot>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| ROOT closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mroot>", $3, $2);
  $$ = mtex2MML_copy2(s1, "</mroot>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

raisebox: RAISEBOX TEXTSTRING TEXTSTRING TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='", $2, "' height='");
  char * s2 = mtex2MML_copy3(s1, $3, "' depth='");
  char * s3 = mtex2MML_copy3(s2, $4, "'>");
  $$ = mtex2MML_copy3(s3, $5, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
  mtex2MML_free_string($5);
}
| RAISEBOX NEG TEXTSTRING TEXTSTRING TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='-", $3, "' height='");
  char * s2 = mtex2MML_copy3(s1, $4, "' depth='");
  char * s3 = mtex2MML_copy3(s2, $5, "'>");
  $$ = mtex2MML_copy3(s3, $6, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
  mtex2MML_free_string($5);
  mtex2MML_free_string($6);
}
| RAISEBOX TEXTSTRING TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='", $2, "' height='");
  char * s2 = mtex2MML_copy3(s1, $3, "' depth='depth'>");
  $$ = mtex2MML_copy3(s2, $4, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
}
| RAISEBOX NEG TEXTSTRING TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='-", $3, "' height='");
  char * s2 = mtex2MML_copy3(s1, $4, "' depth='+");
  char * s3 = mtex2MML_copy3(s2, $3, "'>");
  $$ = mtex2MML_copy3(s3, $5, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
  mtex2MML_free_string($5);
}
| RAISEBOX TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='", $2, "' height='+");
  char * s2 = mtex2MML_copy3(s1, $2, "' depth='depth'>");
  $$ = mtex2MML_copy3(s2, $3, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
}
| RAISEBOX NEG TEXTSTRING closedTerm {
  char * s1 = mtex2MML_copy3("<mpadded voffset='-", $3, "' height='0pt' depth='+");
  char * s2 = mtex2MML_copy3(s1, $3, "'>");
  $$ = mtex2MML_copy3(s2, $4, "</mpadded>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
};

munder: XARROW OPTARGOPEN compoundTermList OPTARGCLOSE EMPTYMROW {
  char * s1 = mtex2MML_copy3("<munder><mo>", $1, "</mo><mrow>");
  $$ = mtex2MML_copy3(s1, $3, "</mrow></munder>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
}
| UNDER closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<munder>", $3, $2);
  $$ = mtex2MML_copy2(s1, "</munder>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

mover: XARROW closedTerm {
  char * s1 = mtex2MML_copy3("<mover><mo>", $1, "</mo>");
  $$ =  mtex2MML_copy3(s1, $2, "</mover>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
}
| OVER closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<mover>", $3, $2);
  $$ = mtex2MML_copy2(s1, "</mover>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
};

munderover: XARROW OPTARGOPEN compoundTermList OPTARGCLOSE closedTerm {
  char * s1 = mtex2MML_copy3("<munderover><mo>", $1, "</mo><mrow>");
  char * s2 = mtex2MML_copy3(s1, $3, "</mrow>");
  $$ = mtex2MML_copy3(s2, $5, "</munderover>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
}
| UNDEROVER closedTerm closedTerm closedTerm {
  char * s1 = mtex2MML_copy3("<munderover>", $4, $2);
  $$ = mtex2MML_copy3(s1, $3, "</munderover>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
  mtex2MML_free_string($3);
  mtex2MML_free_string($4);
};

emptymrow: EMPTYMROW {
  $$ = mtex2MML_copy_string("<mrow/>");
};

mathenv: BEGINENV MATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV MATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV MATRIX ST rowLinesDefList END tableRowList ENDENV MATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV MATRIX tableRowList ENDENV MATRIX {
  $$ = mtex2MML_copy3("<mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV GATHERED ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV GATHERED {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"true\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV GATHERED ST rowLinesDefList END tableRowList ENDENV GATHERED {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"true\" rowspacing=\"1.0ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV GATHERED tableRowList ENDENV GATHERED {
  $$ = mtex2MML_copy3("<mrow><mtable displaystyle=\"true\" rowspacing=\"1.0ex\">", $3, "</mtable></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV PMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV PMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>(</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow><mo>)</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV PMATRIX ST rowLinesDefList END tableRowList ENDENV PMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>(</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow><mo>)</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV PMATRIX tableRowList ENDENV PMATRIX {
  $$ = mtex2MML_copy3("<mrow><mo>(</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow><mo>)</mo></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV BMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV BMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>[</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow><mo>]</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV BMATRIX ST rowLinesDefList END tableRowList ENDENV BMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>[</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow><mo>]</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV BMATRIX tableRowList ENDENV BMATRIX {
  $$ = mtex2MML_copy3("<mrow><mo>[</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow><mo>]</mo></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV VMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV VMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>&VerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow><mo>&VerticalBar;</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV VMATRIX ST rowLinesDefList END tableRowList ENDENV VMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>&VerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow><mo>&VerticalBar;</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV VMATRIX tableRowList ENDENV VMATRIX {
  $$ = mtex2MML_copy3("<mrow><mo>&VerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow><mo>&VerticalBar;</mo></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV BBMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV BBMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow><mo>}</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV BBMATRIX ST rowLinesDefList END tableRowList ENDENV BBMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow><mo>}</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV BBMATRIX tableRowList ENDENV BBMATRIX {
  $$ = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow><mo>}</mo></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV VVMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV VVMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>&DoubleVerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow><mo>&DoubleVerticalBar;</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV VVMATRIX ST rowLinesDefList END tableRowList ENDENV VVMATRIX {
  char *s1 = mtex2MML_copy3("<mrow><mo>&DoubleVerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow><mo>&DoubleVerticalBar;</mo></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV VVMATRIX tableRowList ENDENV VVMATRIX {
  $$ = mtex2MML_copy3("<mrow><mo>&DoubleVerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow><mo>&DoubleVerticalBar;</mo></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV SMALLMATRIX ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV SMALLMATRIX {
  char *s1 = mtex2MML_copy3("<mstyle scriptlevel=\"2\"><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow></mstyle>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV SMALLMATRIX ST rowLinesDefList END tableRowList ENDENV SMALLMATRIX {
  char *s1 = mtex2MML_copy3("<mstyle scriptlevel=\"2\"><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow></mstyle>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV SMALLMATRIX tableRowList ENDENV SMALLMATRIX {
  $$ = mtex2MML_copy3("<mstyle scriptlevel=\"2\"><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow></mstyle>");
  mtex2MML_free_string($3);
}
| BEGINENV CASES ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV CASES {
  char * s1 = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char * s2 = mtex2MML_copy3(s1, $6, "\" columnalign=\"left left\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV CASES ST rowLinesDefList END tableRowList ENDENV CASES {
  char * s1 = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\" columnalign=\"left left\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV CASES tableRowList ENDENV CASES {
  $$ = mtex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" columnalign=\"left left\">", $3, "</mtable></mrow></mrow>");
  mtex2MML_free_string($3);
}
| BEGINENV ALIGNED ST rowSpacingDefList END rowLinesDefList END tableRowList ENDENV ALIGNED {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"true\" columnalign=\"right left right left right left right left right left\" columnspacing=\"0em\" rowspacing=\"", $4, "\" rowlines=\"");
  char *s2 = mtex2MML_copy3(s1, $6, "\">");
  $$ = mtex2MML_copy3(s2, $8, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV ALIGNED ST rowLinesDefList END tableRowList ENDENV ALIGNED {
  char *s1 = mtex2MML_copy3("<mrow><mtable displaystyle=\"true\" columnalign=\"right left right left right left right left right left\" columnspacing=\"0em\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\">");
  $$ = mtex2MML_copy3(s1, $6, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV ARRAY ARRAYALIGN ST columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($5);
  char *column_align = remove_excess_pipe_chars($5);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" align=\"", $3, "\" columnalign=\"");
  char * s2 = mtex2MML_copy3(s1, column_align, "\" ");
  char * s3 = mtex2MML_copy3(s2, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s3, $7, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
  mtex2MML_free_string($7);
}
| BEGINENV ARRAY ARRAYALIGN ST rowLinesDefList END columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($7);
  char *column_align = remove_excess_pipe_chars($7);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" align=\"", $3, "\" rowlines=\"");
  char * s2 = mtex2MML_copy3(s1, $5, "\" columnalign=\"");
  char * s3 = mtex2MML_copy3(s2, column_align, "\" ");
  char * s4 = mtex2MML_copy3(s3, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s4, $9, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string(s4);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
  mtex2MML_free_string($7);
  mtex2MML_free_string($9);
}
| BEGINENV ARRAY ARRAYALIGN ST rowSpacingDefList END rowLinesDefList END columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($9);
  char *column_align = remove_excess_pipe_chars($9);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" align=\"", $3, "\" rowspacing=\"");
  char * s2 = mtex2MML_copy3(s1, $5, "\" rowlines=\"");
  char * s3 = mtex2MML_copy3(s2, $7, "\" columnalign=\"");
  char * s4 = mtex2MML_copy3(s3, column_align, "\" ");
  char * s5 = mtex2MML_copy3(s4, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s5, $11, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string(s4);
  mtex2MML_free_string(s5);
  mtex2MML_free_string($3);
  mtex2MML_free_string($7);
  mtex2MML_free_string($9);
  mtex2MML_free_string($11);
}
| BEGINENV ARRAY ST rowSpacingDefList END rowLinesDefList END columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($8);
  char *column_align = remove_excess_pipe_chars($8);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"", $4, "\" rowlines=\"");
  char * s2 = mtex2MML_copy3(s1, $6,"\" columnalign=\"");
  char * s3 = mtex2MML_copy3(s2, column_align, "\" ");
  char * s4 = mtex2MML_copy3(s3, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s4, $10, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string(s4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
  mtex2MML_free_string($10);
}
| BEGINENV ARRAY ST rowSpacingDefList END columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($6);
  char *column_align = remove_excess_pipe_chars($6);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"", $4, "\" columnalign=\"");
  char * s2 = mtex2MML_copy3(s1, column_align, "\" ");
  char * s3 = mtex2MML_copy3(s2, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s3, $8, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV ARRAY ST rowLinesDefList END columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($6);
  char *column_align = remove_excess_pipe_chars($6);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" rowlines=\"", $4, "\" columnalign=\"");
  char * s2 = mtex2MML_copy3(s1, column_align, "\" ");
  char * s3 = mtex2MML_copy3(s2, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s3, $8, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string(s3);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
  mtex2MML_free_string($8);
}
| BEGINENV ARRAY ST columnAlignList END tableRowList ENDENV ARRAY {
  char *pipe_chars = vertical_pipe_extract($4);
  char *column_align = remove_excess_pipe_chars($4);

  char * s1 = mtex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" columnalign=\"", column_align, "\" ");
  char * s2 = mtex2MML_copy3(s1, pipe_chars, "\">");
  $$ = mtex2MML_copy3(s2, $6, "</mtable>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string(s2);
  mtex2MML_free_string($4);
  mtex2MML_free_string($6);
}
| BEGINENV SVG XMLSTRING ENDSVG {
  $$ = mtex2MML_copy3("<semantics><annotation-xml encoding=\"SVG1.1\">", $3, "</annotation-xml></semantics>");
  mtex2MML_free_string($3);
}
| BEGINENV SVG ENDSVG {
  $$ = mtex2MML_copy_string(" ");
};

rowSpacingDefList: rowSpacingDefList ROWSPACINGDEF {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
}
| ROWSPACINGDEF {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

rowLinesDefList: rowLinesDefList ROWLINESDEF {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
}
| ROWLINESDEF {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

columnAlignList: columnAlignList COLUMNALIGN {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
}
| COLUMNALIGN {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

substack: SUBSTACK MROWOPEN tableRowList MROWCLOSE {
  $$ = mtex2MML_copy3("<mrow><mtable columnalign=\"center\" rowspacing=\"0.5ex\">", $3, "</mtable></mrow>");
  mtex2MML_free_string($3);
};

array: ARRAY MROWOPEN tableRowList MROWCLOSE {
  $$ = mtex2MML_copy3("<mrow><mtable>", $3, "</mtable></mrow>");
  mtex2MML_free_string($3);
}
| ARRAY MROWOPEN ARRAYOPTS MROWOPEN arrayopts MROWCLOSE tableRowList MROWCLOSE {
  char * s1 = mtex2MML_copy3("<mrow><mtable ", $5, ">");
  $$ = mtex2MML_copy3(s1, $7, "</mtable></mrow>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($5);
  mtex2MML_free_string($7);
};

arrayopts: anarrayopt {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| arrayopts anarrayopt {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

anarrayopt: collayout {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| colalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| align {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| eqrows {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| eqcols {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowlines {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| collines {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| frame {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| padding {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

collayout: COLLAYOUT ATTRLIST {
  $$ = mtex2MML_copy2("columnalign=", $2);
  mtex2MML_free_string($2);
};

colalign: COLALIGN ATTRLIST {
  $$ = mtex2MML_copy2("columnalign=", $2);
  mtex2MML_free_string($2);
};

rowalign: ROWALIGN ATTRLIST {
  $$ = mtex2MML_copy2("rowalign=", $2);
  mtex2MML_free_string($2);
};

align: ALIGN ATTRLIST {
  $$ = mtex2MML_copy2("align=", $2);
  mtex2MML_free_string($2);
};

eqrows: EQROWS ATTRLIST {
  $$ = mtex2MML_copy2("equalrows=", $2);
  mtex2MML_free_string($2);
};

eqcols: EQCOLS ATTRLIST {
  $$ = mtex2MML_copy2("equalcolumns=", $2);
  mtex2MML_free_string($2);
};

rowlines: ROWLINES ATTRLIST {
  $$ = mtex2MML_copy2("rowlines=", $2);
  mtex2MML_free_string($2);
};

collines: COLLINES ATTRLIST {
  $$ = mtex2MML_copy2("columnlines=", $2);
  mtex2MML_free_string($2);
};

frame: FRAME ATTRLIST {
  $$ = mtex2MML_copy2("frame=", $2);
  mtex2MML_free_string($2);
};

padding: PADDING ATTRLIST {
  char * s1 = mtex2MML_copy3("rowspacing=", $2, " columnspacing=");
  $$ = mtex2MML_copy2(s1, $2);
  mtex2MML_free_string(s1);
  mtex2MML_free_string($2);
};

tableRowList: tableRow {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| tableRowList ROWSEP tableRow {
  $$ = mtex2MML_copy3($1, " ", $3);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
};

tableRow: simpleTableRow {
  $$ = mtex2MML_copy3("<mtr>", $1, "</mtr>");
  mtex2MML_free_string($1);
}
| optsTableRow {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

simpleTableRow: tableCell {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| simpleTableRow COLSEP tableCell {
  $$ = mtex2MML_copy3($1, " ", $3);
  mtex2MML_free_string($1);
  mtex2MML_free_string($3);
};

optsTableRow: ROWOPTS MROWOPEN rowopts MROWCLOSE simpleTableRow {
  char * s1 = mtex2MML_copy3("<mtr ", $3, ">");
  $$ = mtex2MML_copy3(s1, $5, "</mtr>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
};

rowopts: arowopt {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowopts arowopt {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

arowopt: colalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

tableCell:   {
  $$ = mtex2MML_copy_string("<mtd/>");
}
| compoundTermList {
  $$ = mtex2MML_copy3("<mtd>", $1, "</mtd>");
  mtex2MML_free_string($1);
}
| CELLOPTS MROWOPEN cellopts MROWCLOSE compoundTermList {
  char * s1 = mtex2MML_copy3("<mtd ", $3, ">");
  $$ = mtex2MML_copy3(s1, $5, "</mtd>");
  mtex2MML_free_string(s1);
  mtex2MML_free_string($3);
  mtex2MML_free_string($5);
};

cellopts: acellopt {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| cellopts acellopt {
  $$ = mtex2MML_copy3($1, " ", $2);
  mtex2MML_free_string($1);
  mtex2MML_free_string($2);
};

acellopt: colalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowalign {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| rowspan {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
}
| colspan {
  $$ = mtex2MML_copy_string($1);
  mtex2MML_free_string($1);
};

rowspan: ROWSPAN ATTRLIST {
  $$ = mtex2MML_copy2("rowspan=", $2);
  mtex2MML_free_string($2);
};

colspan: COLSPAN ATTRLIST {
  $$ = mtex2MML_copy2("columnspan=", $2);
  mtex2MML_free_string($2);
};

%%

const char *format_additions(const char *string) {
  if (colors == NULL)
    create_css_colors(&colors);

  return env_replacements(string);
}

char * mtex2MML_parse (const char * buffer, unsigned long length)
{
  char * mathml = 0;

  int result;

  const char *replaced_buffer = format_additions(buffer);
  mtex2MML_setup (replaced_buffer, strlen(replaced_buffer));
  mtex2MML_restart ();

  result = mtex2MML_yyparse (&mathml);

  if (result && mathml) /* shouldn't happen? */
    {
      mtex2MML_free_string (mathml);
      mathml = 0;
    }

  return mathml;
}

int mtex2MML_filter (const char * buffer, unsigned long length)
{
  const char *replaced_buffer = format_additions(buffer);
  mtex2MML_setup (replaced_buffer, strlen(replaced_buffer));
  mtex2MML_restart ();

  return mtex2MML_yyparse (0);
}

#define MTEX_DELIMITER_DOLLAR 0
#define MTEX_DELIMITER_DOUBLE 1
#define MTEX_DELIMITER_SQUARE 2

static char * mtex2MML_last_error = 0;

static void mtex2MML_keep_error (const char * msg)
{
  if (mtex2MML_last_error)
    {
      mtex2MML_free_string (mtex2MML_last_error);
      mtex2MML_last_error = 0;
    }
  mtex2MML_last_error = mtex2MML_copy_escaped (msg);
}

int mtex2MML_html_filter (const char * buffer, unsigned long length)
{
  mtex2MML_do_html_filter (buffer, length, 0);
}

int mtex2MML_strict_html_filter (const char * buffer, unsigned long length)
{
  mtex2MML_do_html_filter (buffer, length, 1);
}

int mtex2MML_do_html_filter (const char * buffer, unsigned long length, const int forbid_markup)
{
  int result = 0;

  int type = 0;
  int skip = 0;
  int match = 0;

  const char * ptr1 = buffer;
  const char * ptr2 = 0;

  const char * end = buffer + length;

  char * mathml = 0;

  void (*save_error_fn) (const char * msg) = mtex2MML_error;

  mtex2MML_error = mtex2MML_keep_error;

 _until_math:
  ptr2 = ptr1;

  while (ptr2 < end)
    {
      if (*ptr2 == '$') break;
      if ((*ptr2 == '\\') && (ptr2 + 1 < end))
	{
	  if (*(ptr2+1) == '[') break;
	}
      ++ptr2;
    }
  if (mtex2MML_write && ptr2 > ptr1)
    (*mtex2MML_write) (ptr1, ptr2 - ptr1);

  if (ptr2 == end) goto _finish;

 _until_html:
  ptr1 = ptr2;

  if (ptr2 + 1 < end)
    {
      if ((*ptr2 == '\\') && (*(ptr2+1) == '['))
	{
	  type = MTEX_DELIMITER_SQUARE;
	  ptr2 += 2;
	}
      else if ((*ptr2 == '$') && (*(ptr2+1) == '$'))
	{
	  type = MTEX_DELIMITER_DOUBLE;
	  ptr2 += 2;
	}
      else
	{
	  type = MTEX_DELIMITER_DOLLAR;
	  ptr2 += 2;
	}
    }
  else goto _finish;

  skip = 0;
  match = 0;

  while (ptr2 < end)
    {
      switch (*ptr2)
	{
	case '<':
	case '>':
	  if (forbid_markup == 1) skip = 1;
	  break;

	case '\\':
	  if (ptr2 + 1 < end)
	    {
	      if (*(ptr2 + 1) == '[')
		{
		  skip = 1;
		}
	      else if (*(ptr2 + 1) == ']')
		{
		  if (type == MTEX_DELIMITER_SQUARE)
		    {
		      ptr2 += 2;
		      match = 1;
		    }
		  else
		    {
		      skip = 1;
		    }
		}
	    }
	  break;

	case '$':
	  if (type == MTEX_DELIMITER_SQUARE)
	    {
	      skip = 1;
	    }
	  else if (ptr2 + 1 < end)
	    {
	      if (*(ptr2 + 1) == '$')
		{
		  if (type == MTEX_DELIMITER_DOLLAR)
		    {
		      ptr2++;
		      match = 1;
		    }
		  else
		    {
		      ptr2 += 2;
		      match = 1;
		    }
		}
	      else
		{
		  if (type == MTEX_DELIMITER_DOLLAR)
		    {
		      ptr2++;
		      match = 1;
		    }
		  else
		    {
		      skip = 1;
		    }
		}
	    }
	  else
	    {
	      if (type == MTEX_DELIMITER_DOLLAR)
		{
		  ptr2++;
		  match = 1;
		}
	      else
		{
		  skip = 1;
		}
	    }
	  break;

	default:
	  break;
	}
      if (skip || match) break;

      ++ptr2;
    }
  if (skip)
    {
      if (type == MTEX_DELIMITER_DOLLAR)
	{
	  if (mtex2MML_write)
	    (*mtex2MML_write) (ptr1, 1);
	  ptr1++;
	}
      else
	{
	  if (mtex2MML_write)
	    (*mtex2MML_write) (ptr1, 2);
	  ptr1 += 2;
	}
      goto _until_math;
    }
  if (match)
    {
      mathml = mtex2MML_parse (ptr1, ptr2 - ptr1);

      if (mathml)
	{
	  if (mtex2MML_write_mathml)
	    (*mtex2MML_write_mathml) (mathml);
	  mtex2MML_free_string (mathml);
	  mathml = 0;
	}
      else
	{
	  ++result;
	  if (mtex2MML_write)
	    {
	      if (type == MTEX_DELIMITER_DOLLAR)
		(*mtex2MML_write) ("<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><merror><mtext>", 0);
	      else
		(*mtex2MML_write) ("<math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><merror><mtext>", 0);

	      (*mtex2MML_write) (mtex2MML_last_error, 0);
	      (*mtex2MML_write) ("</mtext></merror></math>", 0);
	    }
	}
      ptr1 = ptr2;

      goto _until_math;
    }
  if (mtex2MML_write)
    (*mtex2MML_write) (ptr1, ptr2 - ptr1);

 _finish:
  if (mtex2MML_last_error)
    {
      mtex2MML_free_string (mtex2MML_last_error);
      mtex2MML_last_error = 0;
    }
  mtex2MML_error = save_error_fn;

  return result;
}

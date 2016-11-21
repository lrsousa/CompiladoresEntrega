grammar MMML;

@header {
import java.util.*;
import java.util.ArrayList;

import NestedPackage.NestedSymbolTable;
import NestedPackage.SymbolEntry;
}

@parser::members {
   public NestedSymbolTable<String> tabelaSimbolo = new NestedSymbolTable<String>();
   
   public String testaTipoNumerosExp(String a, String b) {
		if (a == "string" || b == "string") {
		   return null;
		} else {
		   return "float";
		}
   }
   
   public String testaTipoNumeros(String a, String b) {
		if (a == "string" || b == "string") {
		   return null;
		} else if (a == "float" || b == "float") {
		   return "float";
		} else {
			return "int";
		}
   }
   
   public String testaBool(String a, String b) {
		if (a == "string" || b == "string") {
		   return null;
		} else {
		   return "bool";
		}
   }
   
   private void imprimirTabela() {
      int i= 1;
      for (SymbolEntry<String> entry : tabelaSimbolo.getEntries()) {
         System.out.println(i +" simbolo= "+ entry);
         i++;
      }
   }
   
}


WS : [ \r\t\u000C\n]+ -> channel(HIDDEN)
    ;

COMMENT : '//' ~('\n'|'\r')* '\r'? '\n' -> channel(HIDDEN);

program
    : fdecls maindecl {System.out.println("Parseou um programa!");}
    ;

fdecls
    : fdecl fdecls                                   #fdecls_one_decl_rule
    |                                                #fdecls_end_rule
    ;

maindecl: 'def' 'main' '=' funcbody                  #programmain_rule
    ;

fdecl: 'def' functionname fdeclparams '=' funcbody   #funcdef_rule
    ;

fdeclparams
returns [List<String> plist]
	@init {
	    $plist = new ArrayList<String>();
	}
	@after {
	    for (String s : $plist) {
	        System.out.println("Parametro: " + s);
	    }
	}
    :   fdeclparam
        {
            $plist.add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]						 #fdeclparams_one_param_rule
	|													 #fdeclparams_no_params
    ;

fdeclparams_cont [List<String> plist]
    : ',' fdeclparam
        {
            $plist.add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]						#fdeclparams_cont_rule
    |                                                	#fdeclparams_end_rule
    ;

fdeclparam
returns [String pname, String ptype]
    : symbol ':' type
        {
            $pname = $symbol.text;
            $ptype = $type.text;
        }
        #fdecl_param_rule
    ;

functionname: TOK_ID                                 #fdecl_funcname_rule
    ;

type
returns [String tipo]
	: tipo_basico = basic_type {$tipo = $tipo_basico.tipo;}		#basictype_rule
    | sequence_type
		{
			System.out.println("Variavel do tipo " + $sequence_type.base + " dimensao "+ $sequence_type.dimension);
        } 														#sequencetype_rule
    ;

basic_type
returns [String tipo]
    : 'int'		{$tipo = "int";}
    | 'bool'	{$tipo = "bool";}
    | 'str'		{$tipo = "string";} 
    | 'float'	{$tipo = "float";}
    | 'char'	{$tipo = "char";}
    ;

sequence_type
returns [int dimension=0, String base]
    :   basic_type '[]'
        {
            $dimension = 1;
            $base = $basic_type.text;
        } 											#sequencetype_basetype_rule
    |   s=sequence_type '[]'
        {
            $dimension = $s.dimension + 1;
            $base = $s.base;
        }											#sequencetype_sequence_rule
    ;

funcbody
returns [String tipo]
	:	ifexpr                                       #fbody_if_rule
    |   letexpr {$tipo = $letexpr.tipo;}                                      #fbody_let_rule
    |   metaexpr { $tipo = $metaexpr.tipo; imprimirTabela();}       		  #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
returns [NestedSymbolTable<String> tabela, String tipo]
    : 'let' letlist 'in' {tabelaSimbolo = $letlist.tabela;} funcbody {tabelaSimbolo = tabelaSimbolo.getParent(); $tipo = $funcbody.tipo;}                    #letexpression_rule
    ;

letlist
returns [NestedSymbolTable<String> tabela]
	@init
	{
		$tabela = new NestedSymbolTable<String>();
	}
    : letvarexpr[$tabela] {$tabela.store($letvarexpr.nome, $letvarexpr.tipo);} letlist_cont[$tabela]                             #letlist_rule
    ;

letlist_cont [NestedSymbolTable<String> tabela]
    : ',' letvarexpr[$tabela] {$tabela.store($letvarexpr.nome, $letvarexpr.tipo);} letlist_cont[$tabela]                    #letlist_cont_rule
    |                                                				   #letlist_cont_end
    ;

letvarexpr [NestedSymbolTable<String> tabela]
returns [String nome, String tipo]
    :    symbol {$nome = $symbol.text;} '=' funcbody {$tipo = $funcbody.tipo;}                         						 #letvarattr_rule
    |    '_'    '=' funcbody {$nome = "_"; $tipo = $funcbody.tipo;}                         #letvarresult_ignore_rule
    |    esquerda = symbol '::' direita = symbol {$nome = $esquerda.text + $direita.text;} '=' funcbody {$tipo = $funcbody.tipo;}              #letunpack_rule
    ;

metaexpr
returns [String tipo]
    : '(' fbody = funcbody ')'
    	{
    		$tipo = $fbody.tipo;
    	}                               			 #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG simbolo = symbol {
    		if($simbolo.tipo == "string") {
	    		$tipo = "string";
    		} else {
	    		$tipo = "int";
    			
    		}
    		
    	}											 #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'
    	{
    		
    	}					                        #me_boolnegparens_rule  //        or anything in between ( )
    | esquerda = metaexpr TOK_POWER direita = metaexpr
    	{
    		$tipo = testaTipoNumerosExp($esquerda.tipo, $direita.tipo);
    	}                    						 #me_exprpower_rule      // Exponentiation
    | esquerda = metaexpr TOK_CONCAT direita = metaexpr
    	{
    		if($esquerda.tipo == "string" || $direita.tipo == "string") {
    			$tipo = "string";
    		}
    	}                   						 #me_listconcat_rule     // Sequence concatenation
    | esquerda = metaexpr TOK_DIV_OR_MUL direita = metaexpr
    	{
    		$tipo = testaTipoNumeros($esquerda.tipo, $direita.tipo);
		}                							 #me_exprmuldiv_rule     // Div and Mult are equal
    | esquerda = metaexpr TOK_PLUS_OR_MINUS direita = metaexpr
    	{
    		$tipo = testaTipoNumeros($esquerda.tipo, $direita.tipo);
    	}            								 #me_exprplusminus_rule  // Sum and Sub are equal
    | esquerda = metaexpr TOK_CMP_GT_LT direita = metaexpr
    	{
    		$tipo = testaBool($esquerda.tipo, $direita.tipo);
    	}                							 #me_boolgtlt_rule       // < <= >= > are equal
    | esquerda = metaexpr TOK_CMP_EQ_DIFF direita = metaexpr
    	{
    		$tipo = testaBool($esquerda.tipo, $direita.tipo);
    	} 								             #me_booleqdiff_rule     // == and != are egual
	| esquerda = metaexpr TOK_BOOL_AND_OR direita = metaexpr
		{
			$tipo = testaBool($esquerda.tipo, $direita.tipo);
		}											 #me_boolandor_rule      // &&   and  ||  are equal
    | symbol
		{
			if(tabelaSimbolo.lookup($symbol.text) != null) {
			   $tipo = tabelaSimbolo.lookup($symbol.text).symbol;
			}
			
		}                                            #me_exprsymbol_rule     // a single symbol
    | literal {$tipo = $literal.tipo;}                                            #me_exprliteral_rule    // literal value
    | funcall                                        #me_exprfuncall_rule    // a funcion call
    | cast {$tipo = $cast.tipo;}                     #me_exprcast_rule       // cast a type to other
    ;

sequence_expr
    : '[' funcbody ']'                               #se_create_seq
    ;

funcall
	: symbol funcall_params                       #funcall_rule	
    ;

cast
returns [String tipo]
    : c = type funcbody {$tipo = $c.tipo;}            #cast_rule
    ;

funcall_params
    :   metaexpr funcall_params_cont                    #funcallparams_rule
    |   '_'                                             #funcallnoparam_rule
    ;

funcall_params_cont
    : metaexpr funcall_params_cont                      #funcall_params_cont_rule
    |                                                   #funcall_params_end_rule
    ;

literal
returns [String tipo]
	: 'nil'                                           #literalnil_rule
    | 'true' {$tipo = "bool";}                         #literaltrue_rule
    | number {$tipo = $number.tipo;}                   #literalnumber_rule
    | strlit { $tipo = "string";}                      #literalstring_rule
    | charlit {$tipo = "char";}                        #literal_char_rule
    ;

strlit
returns [String tipo]
	: TOK_STR_LIT
    ;

charlit
returns [String tipo]
    : TOK_CHAR_LIT
    ;

number
returns [String tipo]
	: FLOAT {$tipo = "float";}                        #numberfloat_rule
    | DECIMAL {$tipo = "int";}                        #numberdecimal_rule
    | HEXADECIMAL {$tipo = "int";}                    #numberhexadecimal_rule
    | BINARY {$tipo = "int";}                         #numberbinary_rule
	;

symbol
returns [String tipo]
	: TOK_ID
	{

	}                                          		 #symbol_rule
    ;


// id: begins with a letter, follows letters, numbers or underscore
TOK_ID: [a-zA-Z]([a-zA-Z0-9_]*);

TOK_CONCAT: '::' ;
TOK_NEG: '!';
TOK_POWER: '^' ;
TOK_DIV_OR_MUL: ('/'|'*');
TOK_PLUS_OR_MINUS: ('+'|'-');
TOK_CMP_GT_LT: ('<='|'>='|'<'|'>');
TOK_CMP_EQ_DIFF: ('=='|'!=');
TOK_BOOL_AND_OR: ('&&'|'||');

TOK_REL_OP : ('>'|'<'|'=='|'>='|'<=') ;

TOK_STR_LIT
  : '"' (~[\"\\\r\n] | '\\' (. | EOF))* '"'
  ;


TOK_CHAR_LIT
    : '\'' (~[\'\n\r\\] | '\\' (. | EOF)) '\''
    ;

FLOAT : '-'? DEC_DIGIT+ '.' DEC_DIGIT+([eE][\+-]? DEC_DIGIT+)? ;


DECIMAL : '-'? DEC_DIGIT+ ;

HEXADECIMAL : '0' 'x' HEX_DIGIT+ ;

BINARY : BIN_DIGIT+ 'b' ; // Sequencia de digitos seguida de b  10100b

fragment
BIN_DIGIT : [01];

fragment
HEX_DIGIT : [0-9A-Fa-f];

fragment
DEC_DIGIT : [0-9] ;

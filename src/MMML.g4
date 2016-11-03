grammar MMML;

@header {
import java.util.*;
}

@parser::members {
   public String testaTipoNumeros(String a, String b) {
       if (a == "int" && b == "int") {
		   return "int";
		} else if (a == "float" && b == "float") {
		   return "float";
		}
		else if ((a == "int" && b == "float") || (a == "float" && b == "float"))
		{
			return "float";
		}
		return null;
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
        fdeclparams_cont[$plist]

                                                     #fdeclparams_one_param_rule
    |                                                #fdeclparams_no_params
    ;

fdeclparams_cont[List<String> plist]
    : ',' fdeclparam
        {
            $plist.add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]
                                                     #fdeclparams_cont_rule
    |                                                #fdeclparams_end_rule
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

funcbody:
        ifexpr                                       #fbody_if_rule
    |   letexpr                                      #fbody_let_rule
    |   metaexpr                                     #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
    : 'let' letlist 'in' funcbody                    #letexpression_rule
    ;

letlist
    : letvarexpr  letlist_cont                       #letlist_rule
    ;

letlist_cont
    : ',' letvarexpr letlist_cont                    #letlist_cont_rule
    |                                                #letlist_cont_end
    ;

letvarexpr
    :    symbol '=' funcbody                         #letvarattr_rule
    |    '_'    '=' funcbody                         #letvarresult_ignore_rule
    |    symbol '::' symbol '=' funcbody             #letunpack_rule
    ;

metaexpr
returns [String tipo]
    : '(' funcbody ')'                               #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG symbol                                 
    	{
    		$tipo = "bool";
    	}											 #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'
    	{
    		$tipo = "bool";
    	}					                        #me_boolnegparens_rule  //        or anything in between ( )
    | esquerda = metaexpr TOK_POWER direita = metaexpr
    	{
    		$tipo = testaTipoNumeros($esquerda.tipo, $direita.tipo);
    	}                    						 #me_exprpower_rule      // Exponentiation
    | esquerda = metaexpr TOK_CONCAT direita = metaexpr
    	{
    		if($esquerda.tipo == "string" && $direita.tipo == "string")
    		{
    			$tipo = "string";
    		}
    	}                   						 #me_listconcat_rule     // Sequence concatenation
    | esquerda = metaexpr TOK_DIV_OR_MUL direita = metaexpr
    	{
    		$tipo = testaTipoNumeros($esquerda.tipo, $direita.tipo);
    								}                #me_exprmuldiv_rule     // Div and Mult are equal
    | esquerda = metaexpr TOK_PLUS_OR_MINUS direita = metaexpr
    	{
    		$tipo = testaTipoNumeros($esquerda.tipo, $direita.tipo);
    	}            								 #me_exprplusminus_rule  // Sum and Sub are equal
    | metaexpr TOK_CMP_GT_LT metaexpr
    	{
    		$tipo = "bool";
    	}                							 #me_boolgtlt_rule       // < <= >= > are equal
    | metaexpr TOK_CMP_EQ_DIFF metaexpr
    	{
    		$tipo = "bool";
    	} 								             #me_booleqdiff_rule     // == and != are egual
    | metaexpr TOK_BOOL_AND_OR metaexpr              #me_boolandor_rule      // &&   and  ||  are equal
    | symbol
		{
			$tipo = $symbol.tipo;
		}                                            #me_exprsymbol_rule     // a single symbol
    | literal
    	{
    		$tipo = $literal.tipo;
    	}                                            #me_exprliteral_rule    // literal value
    | funcall                                        #me_exprfuncall_rule    // a funcion call
    | cast
    	{
    		$tipo = $cast.tipo;
    	}                                            #me_exprcast_rule       // cast a type to other
    ;

sequence_expr
    : '[' funcbody ']'                               #se_create_seq
    ;

funcall: symbol funcall_params                       #funcall_rule
        /*{
            System.Console.WriteLine("Uma chamada de funcao! {0}", $symbol.text);
        }*/
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
    | 'true'                                          #literaltrue_rule
    | number
    	{
    		System.out.println("Antigos espiritos do mal, transformem essa forma decadente em Mun-Ra, o de vida eterna!");
    		$tipo = $number.tipo;
    	}  							                  #literalnumber_rule
    | strlit                                          #literalstring_rule
    | charlit                                         #literal_char_rule
    ;

strlit: TOK_STR_LIT
    ;

charlit
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
: simbolo = TOK_ID
	{
		switch($simbolo.text)
		{
			case "i" : $tipo = "int"; break;
			case "f" : $tipo = "float"; break;
			case "s" : $tipo = "string"; break;
			case "c" : $tipo = "char"; break;
			case "b" : $tipo = "bool"; break;
		}
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

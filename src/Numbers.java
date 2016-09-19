import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.util.Stack;

import org.antlr.v4.runtime.*; // class ANTLRInputStream , Token

import parser.NumbersLexer;

public class Numbers {
	public static void main(String[] args) throws FileNotFoundException {
		Token tk;
		NumbersLexer lexer;
		InputStream is = new FileInputStream("arquivo.kenai");

		Stack<Number> pilha = new Stack<Number>();
		Stack<String> pilhaSinais = new Stack<String>();

		try {
			lexer = new NumbersLexer(new ANTLRInputStream(is));
			is.close();
		} catch (Exception e) {
			// Charmander!
			System.out.println("Erro:" + e);
			System.exit(1);
			return;
		}

		do {
			tk = lexer.nextToken();
			switch (tk.getType()) {
			case NumbersLexer.EXPRESSAO:
				System.out.println("EXPRESSAO: " + tk.getText());
				break;
			case NumbersLexer.COMANDO_STATUS:
				imprimirPilha(pilha);
				break;
			case NumbersLexer.COMANDO_RESET:
				pilha = new Stack<Number>();
				System.out.println("reset");
				break;
			}
		} while (tk != null && tk.getType() != Token.EOF);

	}

	static void imprimirPilha(Stack<Number> pilha) {
		for (int i = pilha.size() - 1; i >= 0; i--) {
			System.out.print("$" + (pilha.size() - i) + " = ");
			if (pilha.get(i).doubleValue() % 1 == 0)
				System.out.println(pilha.get(i).longValue());
			else
				System.out.println(pilha.get(i).doubleValue());
		}
	}

	static void calcula(Stack<Number> pilha, int operador) {
		if (pilha.size() < 2) {
			System.out.println("Pilha com menos de 2 valores numericos");
			return;
		}
		Number v1 = pilha.pop();
		Number v2 = pilha.pop();
		Number retorno = 0;
		switch (operador) {
		case 1:
			retorno = v2.doubleValue() + v1.doubleValue();
			break;
		case 2:
			retorno = v2.doubleValue() - v1.doubleValue();
			break;
		case 3:
			retorno = v2.doubleValue() * v1.doubleValue();
			break;
		case 4:
			retorno = v2.doubleValue() / v1.doubleValue();
			break;
		case 5:
			retorno = Math.pow(v2.doubleValue(), v1.doubleValue());
			break;
		}

		if (Double.isInfinite((double) retorno)) {
			pilha.add(v2);
			pilha.add(v1);
			return;
		}

		if (retorno.doubleValue() % 1 == 0) {
			retorno = retorno.longValue();
		}
		pilha.add(retorno);
		System.out.println("$1 = " + retorno.doubleValue());
		return;
	}
}
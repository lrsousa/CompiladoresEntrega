import org.antlr.v4.runtime.*; // class ANTLRInputStream , Token

import java.io.*;
import javax.swing.JFileChooser;
import javax.swing.filechooser.*;

import parser.MMMLLexer;
import parser.MMMLParser;
import parser.MMMLParser.MetaexprContext;

public class RunParser {
    public static void main(String[] args) throws Exception {
        MMMLLexer lexer;
        MMMLParser parser;

        JFileChooser chooser = new JFileChooser();
        FileNameExtensionFilter filter = new FileNameExtensionFilter("mimimil source code", "mmm");
        chooser.setFileFilter(filter);
        chooser.setCurrentDirectory(new File(System.getProperty("user.dir")));
        int retval = chooser.showOpenDialog(null);
        if (retval != JFileChooser.APPROVE_OPTION)
            return;

        File input = chooser.getSelectedFile();

        try {
            FileInputStream fin = new FileInputStream(input);
            lexer = new MMMLLexer(new ANTLRInputStream(fin));
            CommonTokenStream tokens = new CommonTokenStream(lexer);
            parser = new MMMLParser(tokens);
            MetaexprContext opa = parser.metaexpr();
            System.out.println(opa.tipo);
            
        } catch (Exception e) {
            // Pikachu!
            System.out.println("Erro:" + e);
            System.exit(1);
            return;
        }
    }

}

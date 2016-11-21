package NestedPackage;

public class SymbolEntry<T> {
	public T symbol;
    public int offset;
    public int size;
    public String nome;

    public SymbolEntry(String nome, T symbol, int offset, int size) {
        this.symbol = symbol;
        this.offset = offset;
        this.size = size;
        this.nome = nome;
    }
    
    public String toString() {
        return "Entry at " + offset +
                ", size: " + size +
                ", value: " + symbol +
                ", nome: " + nome;
    }
}
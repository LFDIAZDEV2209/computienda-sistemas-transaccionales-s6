package edu.computienda;
import com.mysql.cj.jdbc.MysqlDataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

/** Ejecutable de demostración para NetBeans: consulta catálogo y compra opcional. */
public final class Main {
    public static void main(String[] args) throws Exception {
        MysqlDataSource ds = new MysqlDataSource();
        ds.setURL(System.getenv().getOrDefault("DB_URL", "jdbc:mysql://localhost:3307/computienda"));
        ds.setUser(System.getenv().getOrDefault("DB_USER", "computienda"));
        ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "computienda2026"));
        try (Connection cn=ds.getConnection(); Statement st=cn.createStatement();
             ResultSet rs=st.executeQuery("SELECT codigo_producto,nombre,cantidad_inventario,precio_venta FROM Productos")) {
            while(rs.next()) System.out.printf("%d | %s | stock=%d | precio=%s%n", rs.getInt(1),rs.getString(2),rs.getInt(3),rs.getBigDecimal(4));
        }
        if (args.length==3) {
            long id = new CompraService(ds).registrarCompra(Integer.parseInt(args[0]),Integer.parseInt(args[1]),Integer.parseInt(args[2]));
            System.out.println("Compra confirmada: " + id);
        }
    }
}

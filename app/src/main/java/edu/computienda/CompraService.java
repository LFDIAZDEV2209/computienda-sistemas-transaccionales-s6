package edu.computienda;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.sql.DataSource;

/** Servicio de ventas: cada operación crítica usa una transacción ACID. */
public final class CompraService {
    private final DataSource dataSource;

    public CompraService(DataSource dataSource) { this.dataSource = dataSource; }

    public long registrarCompra(int clienteId, int productoId, int cantidad) throws SQLException {
        if (cantidad <= 0) throw new SQLException("La cantidad debe ser positiva");
        try (Connection cn = dataSource.getConnection()) {
            cn.setAutoCommit(false); // JDBC emite BEGIN y COMMIT/ROLLBACK.
            try {
                Inventario item = bloquearProducto(cn, productoId);
                if (item.existencias() < cantidad) throw new SQLException("Inventario insuficiente");
                long compraId = crearCompra(cn, clienteId, productoId, cantidad, item.precio());
                descontarInventario(cn, productoId, cantidad);
                crearFactura(cn, compraId, clienteId, productoId, cantidad, item.precio());
                cn.commit();
                return compraId;
            } catch (SQLException ex) {
                cn.rollback();
                throw ex;
            }
        }
    }

    private Inventario bloquearProducto(Connection cn, int productoId) throws SQLException {
        String sql = "SELECT cantidad_inventario, precio_venta FROM Productos WHERE codigo_producto = ? FOR UPDATE";
        try (PreparedStatement ps = cn.prepareStatement(sql)) { ps.setInt(1, productoId); try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) throw new SQLException("Producto inexistente");
            return new Inventario(rs.getInt(1), rs.getBigDecimal(2));
        }}
    }
    private long crearCompra(Connection cn, int cliente, int producto, int cantidad, BigDecimal precio) throws SQLException {
        String sql = "INSERT INTO Compras(id_cliente,codigo_producto,cantidad_comprada,precio_unitario) VALUES(?,?,?,?)";
        try (PreparedStatement ps = cn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) { ps.setInt(1,cliente); ps.setInt(2,producto); ps.setInt(3,cantidad); ps.setBigDecimal(4,precio); ps.executeUpdate(); try(ResultSet rs=ps.getGeneratedKeys()){ rs.next(); return rs.getLong(1); }}
    }
    private void descontarInventario(Connection cn, int producto, int cantidad) throws SQLException {
        try (PreparedStatement ps=cn.prepareStatement("UPDATE Productos SET cantidad_inventario=cantidad_inventario-? WHERE codigo_producto=?")) { ps.setInt(1,cantidad); ps.setInt(2,producto); ps.executeUpdate(); }
    }
    private void crearFactura(Connection cn, long compra, int cliente, int producto, int cantidad, BigDecimal precio) throws SQLException {
        String sql="INSERT INTO Facturas(id_compra,id_cliente,codigo_producto,cantidad_comprada,precio_unitario,total_factura,nombre_cliente) VALUES(?,?,?,?,?,?,(SELECT nombre FROM Clientes WHERE id_cliente=?))";
        try(PreparedStatement ps=cn.prepareStatement(sql)){ ps.setLong(1,compra);ps.setInt(2,cliente);ps.setInt(3,producto);ps.setInt(4,cantidad);ps.setBigDecimal(5,precio);ps.setBigDecimal(6,precio.multiply(BigDecimal.valueOf(cantidad)));ps.setInt(7,cliente);ps.executeUpdate(); }
    }
    private record Inventario(int existencias, BigDecimal precio) {}
}

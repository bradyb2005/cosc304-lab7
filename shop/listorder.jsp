<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="jdbc.jsp" %>
<!DOCTYPE html>
<html>
<head>
<title>Brady and Harrison's Grocery Order List</title>
</head>
<body>

<h1>Order List</h1>

<%
NumberFormat currFormat = NumberFormat.getCurrencyInstance();

String orderSql = """
    SELECT os.orderId, os.orderDate, os.totalAmount,
           c.firstName, c.lastName
    FROM ordersummary os
    LEFT JOIN customer c ON c.customerId = os.customerId
    ORDER BY os.orderId
    """;

String productSql = """
    SELECT p.productName, op.quantity, op.price,
           op.quantity * op.price AS lineTotal
    FROM orderproduct op
    JOIN product p ON p.productId = op.productId
    WHERE op.orderId = ?
    ORDER BY p.productName
    """;

try (Connection con = getConnection();
     PreparedStatement orderStmt = con.prepareStatement(orderSql);
     PreparedStatement productStmt = con.prepareStatement(productSql);
     ResultSet orders = orderStmt.executeQuery())
{
    while (orders.next())
    {
        int orderId = orders.getInt("orderId");
        String customerName = orders.getString("firstName");
        if (customerName != null)
            customerName += " " + orders.getString("lastName");
        else
            customerName = "Guest";

        out.println("<h2>Order #" + orderId + "</h2>");
        out.println("<p>Date: " + orders.getTimestamp("orderDate")
            + "<br>Customer: " + customerName
            + "<br>Order total: "
            + currFormat.format(orders.getBigDecimal("totalAmount"))
            + "</p>");

        out.println("<table border=\"1\">");
        out.println("<tr><th>Product</th><th>Quantity</th>"
            + "<th>Price</th><th>Subtotal</th></tr>");

        productStmt.setInt(1, orderId);
        try (ResultSet products = productStmt.executeQuery())
        {
            while (products.next())
            {
                out.println("<tr><td>" + products.getString("productName")
                    + "</td><td>" + products.getInt("quantity")
                    + "</td><td>" + currFormat.format(products.getBigDecimal("price"))
                    + "</td><td>" + currFormat.format(products.getBigDecimal("lineTotal"))
                    + "</td></tr>");
            }
        }
        out.println("</table>");
    }
}
catch (SQLException ex)
{
    out.println("<p>Unable to retrieve orders.</p>");
    log("Unable to retrieve orders", ex);
}
%>

</body>
</html>

-- Crear la base de datos "kiddy"
drop database kiddy;
create database kiddy;
use kiddy;

-- Tabla para almacenar la información de los administradores de la tienda
CREATE TABLE tb_admin (
    id_admin INT PRIMARY KEY,
    nombre_admin VARCHAR(50),
    apellido_admin VARCHAR(50),
    telefono_admin INT unique,
    correo_admin VARCHAR(80) unique,
    clave_admin VARCHAR(100)
);

-- Tabla para almacenar la información de los clientes de la tienda
CREATE TABLE tb_cliente (
    id_cliente INT auto_increment PRIMARY KEY,
    estado_cliente BOOLEAN default('ACTIVO' 'INACTIVO'),
    nombre_cliente VARCHAR(50),
    apellido_cliente VARCHAR(50),
    telefono_cliente INT unique,
    correo_cliente VARCHAR(80) unique,
    clave_cliente VARCHAR(100),
    fecha_inicio_cliente DATE
);

CREATE TABLE tb_marca (
    id_marca INT PRIMARY KEY,
    nombre_marca VARCHAR(50),
    logo_marca VARCHAR(100),
    id_producto int
);

CREATE TABLE tb_categoria (
    id_categoria INT PRIMARY KEY,
    nombre_categoria VARCHAR(50),
    descripcion_categoria VARCHAR(100),
    imagen_categoria VARCHAR(100)
);

CREATE TABLE tb_producto (
    id_producto INT PRIMARY KEY,
    nombre_producto VARCHAR(100),
    imagen_producto VARCHAR(100),
    existencias_productos INT,
    estado_producto BOOLEAN default('NO DISPONIBLE' 'DISPONIBLE'),
    descripcion_producto VARCHAR(100),
    precio_producto INT,
    id_categoria INT,
    id_marca INT,
    id_detallepe INT
);

CREATE TABLE tb_pedidos (
    id_pedido INT PRIMARY KEY,
    id_cliente INT,
    id_estado_pedido INT,
    fecha_pedido DATE,
    direccion_pedido VARCHAR(100)
);

CREATE TABLE tb_estado_pedido (
    id_estado_pedido INT PRIMARY KEY,
    nombre_estadope VARCHAR(50)
);

CREATE TABLE tb_detalle_pedido (
    id_detallepe INT PRIMARY KEY,
    id_detalle INT,
    id_producto INT,
    id_pedido INT,
    cantidad_producto VARCHAR(100),
    precio_pedido INT
);

CREATE TABLE tb_valoracion (
    id_valoracion INT PRIMARY KEY,
    id_detalleped INT,
    fecha_valo DATE,
    id_detallepe INT,
    valoracion VARCHAR(50),
    comentario VARCHAR(120),
    estado_comentario BOOLEAN default('NO DISPONIBLE' 'DISPONIBLE')
);

-- Restricción para que el precio de producto sea mayor a 0
ALTER TABLE tb_producto
ADD CONSTRAINT chk_precio_producto CHECK (precio_producto > 0);

ALTER TABLE tb_detalle_pedido
ADD CONSTRAINT chk_cantidad_producto CHECK (cantidad_producto > 0);

ALTER TABLE tb_detalle_pedido
ADD CONSTRAINT chk_precio_total CHECK (precio_pedido > 0);

-- Restricciones de clave externa para mantener la integridad referencial de los datos
ALTER TABLE tb_pedidos
ADD CONSTRAINT fk_id_cliente FOREIGN KEY(id_cliente) REFERENCES tb_cliente(id_cliente);

ALTER TABLE tb_detalle_pedido
ADD CONSTRAINT fk_id_pedido_detalle FOREIGN KEY(id_pedido) REFERENCES tb_pedidos(id_pedido);

ALTER TABLE tb_pedidos
ADD CONSTRAINT fk_id_pedido_estado FOREIGN KEY(id_estado_pedido) REFERENCES tb_estado_pedido(id_estado_pedido);

ALTER TABLE tb_producto
ADD CONSTRAINT fk_id_categoria_producto FOREIGN KEY(id_categoria) REFERENCES tb_categoria(id_categoria);

ALTER TABLE tb_producto
ADD CONSTRAINT fk_id_detalle_producto FOREIGN KEY(id_detallepe) REFERENCES tb_detalle_pedido(id_detallepe);

ALTER TABLE tb_marca
ADD CONSTRAINT fk_id_marca_producto FOREIGN KEY(id_producto) REFERENCES tb_producto(id_producto);

-- Crear un índice en la columna id_detallepe de la tabla tb_valoracion para mejorar el rendimiento de las consultas
CREATE INDEX idx_id_detallepe ON tb_valoracion (id_detallepe);

-- Restricción de clave externa para relacionar tb_detalle_pedido con tb_valoracion
ALTER TABLE tb_detalle_pedido
ADD CONSTRAINT fk_id_detalle_valoracion FOREIGN KEY(id_detalle) REFERENCES tb_valoracion(id_detallepe);

-- funcion de base de datos
DELIMITER //
CREATE FUNCTION calcular_precio_total_pedido(pedido_id INT) RETURNS INT READS SQL DATA
BEGIN
    DECLARE total INT;
    SELECT SUM(dp.cantidad_producto * p.precio_producto) INTO total
    FROM tb_detalle_pedido dp
    JOIN tb_producto p ON dp.id_producto = p.id_producto
    WHERE dp.id_pedido = pedido_id;
    RETURN total;
END //
DELIMITER ;


-- trigger de base de datos

DELIMITER //

CREATE TRIGGER verificar_cliente_activo_antes_insertar_pedido
BEFORE INSERT ON tb_pedidos
FOR EACH ROW
BEGIN
    DECLARE cliente_activo INT;

    -- Verificar si el cliente está activo
    SELECT estado_cliente INTO cliente_activo
    FROM tb_cliente
    WHERE id_cliente = NEW.id_cliente;

    -- Si el cliente no está activo, evitar la inserción del pedido
    IF cliente_activo != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no está activo. No se puede realizar el pedido.';
    END IF;
END;
//

DELIMITER ;

DELIMITER //

CREATE TRIGGER actualizar_valoracion_producto_despues_insertar
AFTER INSERT ON tb_valoracion
FOR EACH ROW
BEGIN
    DECLARE promedio_valoracion DECIMAL(5,2);
    DECLARE cantidad_comentarios INT;

    -- Calcular el promedio de valoración y la cantidad de comentarios para el producto
    SELECT AVG(valoracion), COUNT(*)
    INTO promedio_valoracion, cantidad_comentarios
    FROM tb_valoracion
    WHERE id_detallepe = NEW.id_detallepe;

    -- Actualizar el promedio de valoración y la cantidad de comentarios en la tabla tb_producto
    UPDATE tb_producto
    SET promedio_valoracion = promedio_valoracion, cantidad_comentarios = cantidad_comentarios
    WHERE id_detallepe = NEW.id_detallepe;
END;
//

DELIMITER ;

-- PROCEDIMIENTO DE LA BASE DE DATOS

DELIMITER //

CREATE PROCEDURE insertar_cliente(
    IN p_estado_cliente BOOLEAN,
    IN p_nombre_cliente VARCHAR(50),
    IN p_apellido_cliente VARCHAR(50),
    IN p_telefono_cliente INT,
    IN p_correo_cliente VARCHAR(80),
    IN p_clave_cliente VARCHAR(100),
    IN p_fecha_inicio_cliente DATE
)
BEGIN
    INSERT INTO tb_cliente (estado_cliente, nombre_cliente, apellido_cliente, telefono_cliente, correo_cliente, clave_cliente, fecha_inicio_cliente)
    VALUES (p_estado_cliente, p_nombre_cliente, p_apellido_cliente, p_telefono_cliente, p_correo_cliente, p_clave_cliente, p_fecha_inicio_cliente);
END;
//

DELIMITER ;

CALL insertar_cliente(true, 'Nombre', 'Apellido', 123456789, 'correo@example.com', 'contraseña', '2024-03-08');

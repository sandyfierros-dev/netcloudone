-- =====================================================================
--  NETCLOUD ONE — Base de datos (MySQL / MariaDB · XAMPP)
--  SaaS multi-tenant white-label para comunidades empresariales
--  Importar en phpMyAdmin: Importar > seleccionar este archivo > Continuar
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS netcloud_one;
CREATE DATABASE netcloud_one CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE netcloud_one;

-- ---------------------------------------------------------------------
-- 1. PLATAFORMA / TENANT
-- ---------------------------------------------------------------------
CREATE TABLE empresas (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(150) NOT NULL,
  slug             VARCHAR(80)  NOT NULL UNIQUE,          -- identificador del tenant (ej. subdominio)
  rfc              VARCHAR(13)  NULL,
  correo_contacto  VARCHAR(150) NULL,
  telefono         VARCHAR(20)  NULL,
  sitio_web        VARCHAR(255) NULL,
  estado           ENUM('activa','suspendida','inactiva') NOT NULL DEFAULT 'activa',
  fecha_alta       DATE NOT NULL DEFAULT (CURRENT_DATE),
  creado_en        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Personalización white-label (1:1 con empresa)
CREATE TABLE configuracion_marca (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id            BIGINT UNSIGNED NOT NULL UNIQUE,
  nombre_mostrado       VARCHAR(150) NULL,
  logo_url              VARCHAR(255) NULL,
  favicon_url           VARCHAR(255) NULL,
  color_primario        CHAR(7) NOT NULL DEFAULT '#16A34A',
  color_secundario      CHAR(7) NOT NULL DEFAULT '#0F172A',
  dominio_personalizado VARCHAR(150) NULL UNIQUE,
  actualizado_en        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_marca_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. IDENTIDAD (ONE ID)
-- ---------------------------------------------------------------------
-- Cuenta global: un usuario puede pertenecer a varias empresas
CREATE TABLE usuarios (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre            VARCHAR(100) NOT NULL,
  apellidos         VARCHAR(120) NOT NULL,
  correo            VARCHAR(150) NOT NULL UNIQUE,
  contrasena        VARCHAR(255) NOT NULL,              -- hash bcrypt
  telefono          VARCHAR(20)  NULL,
  fecha_nacimiento  DATE NULL,
  foto_url          VARCHAR(255) NULL,
  es_admin_global   TINYINT(1) NOT NULL DEFAULT 0,     -- Administrador de Netcloud One
  estado            ENUM('activo','inactivo','bloqueado') NOT NULL DEFAULT 'activo',
  ultimo_acceso     DATETIME NULL,
  creado_en         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE restablecimientos_contrasena (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id  BIGINT UNSIGNED NOT NULL,
  token_hash  CHAR(64) NOT NULL UNIQUE,
  expira_en   DATETIME NOT NULL,
  usado_en    DATETIME NULL,
  creado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rest_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. ORGANIZACIÓN (ONE Directory)
-- ---------------------------------------------------------------------
CREATE TABLE areas (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id   BIGINT UNSIGNED NOT NULL,
  nombre       VARCHAR(100) NOT NULL,
  descripcion  VARCHAR(255) NULL,
  creado_en    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_area_empresa (empresa_id, nombre),
  CONSTRAINT fk_area_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Relación N:M Usuario–Empresa. El rol va en la membresía.
CREATE TABLE membresias (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id    BIGINT UNSIGNED NOT NULL,
  empresa_id    BIGINT UNSIGNED NOT NULL,
  area_id       BIGINT UNSIGNED NULL,
  rol           ENUM('administrador','usuario') NOT NULL DEFAULT 'usuario',
  cargo         VARCHAR(100) NULL,
  fecha_socio   DATE NOT NULL DEFAULT (CURRENT_DATE),  -- desde cuándo es socio
  estado        ENUM('activa','pendiente','suspendida','baja') NOT NULL DEFAULT 'activa',
  -- Garantiza UN solo administrador por empresa
  admin_unico   BIGINT UNSIGNED AS (IF(rol = 'administrador', empresa_id, NULL)) STORED,
  creado_en     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuario_empresa (usuario_id, empresa_id),
  UNIQUE KEY uq_admin_unico (admin_unico),
  KEY idx_memb_empresa (empresa_id, estado),
  CONSTRAINT fk_memb_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_memb_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
  CONSTRAINT fk_memb_area    FOREIGN KEY (area_id)    REFERENCES areas(id)    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. FEED (ONE Feed) — publicaciones y noticias
-- ---------------------------------------------------------------------
CREATE TABLE publicaciones (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  membresia_id   BIGINT UNSIGNED NOT NULL,               -- autor
  tipo           ENUM('publicacion','noticia') NOT NULL DEFAULT 'publicacion',
  titulo         VARCHAR(200) NULL,
  contenido      TEXT NOT NULL,
  imagen_url     VARCHAR(255) NULL,
  fijada         TINYINT(1) NOT NULL DEFAULT 0,
  area_id        BIGINT UNSIGNED NULL,                   -- NULL = visible para toda la empresa
  creado_en      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en   DATETIME NULL,
  KEY idx_pub_feed (empresa_id, creado_en),
  CONSTRAINT fk_pub_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas(id)   ON DELETE CASCADE,
  CONSTRAINT fk_pub_membresia FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE CASCADE,
  CONSTRAINT fk_pub_area      FOREIGN KEY (area_id)      REFERENCES areas(id)      ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE comentarios (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  publicacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  contenido       TEXT NOT NULL,
  creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  eliminado_en    DATETIME NULL,
  CONSTRAINT fk_com_pub       FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE,
  CONSTRAINT fk_com_membresia FOREIGN KEY (membresia_id)   REFERENCES membresias(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reacciones (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  publicacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  tipo            ENUM('me_gusta','me_encanta','celebrar','interesante') NOT NULL DEFAULT 'me_gusta',
  creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_reaccion (publicacion_id, membresia_id),
  CONSTRAINT fk_reac_pub       FOREIGN KEY (publicacion_id) REFERENCES publicaciones(id) ON DELETE CASCADE,
  CONSTRAINT fk_reac_membresia FOREIGN KEY (membresia_id)   REFERENCES membresias(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. EVENTOS (ONE Events)
-- ---------------------------------------------------------------------
CREATE TABLE eventos (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,              -- organizador
  titulo          VARCHAR(200) NOT NULL,
  descripcion     TEXT NULL,
  modalidad       ENUM('presencial','virtual','hibrido') NOT NULL DEFAULT 'presencial',
  ubicacion       VARCHAR(255) NULL,
  enlace_virtual  VARCHAR(255) NULL,
  fecha_inicio    DATETIME NOT NULL,
  fecha_fin       DATETIME NOT NULL,
  cupo            INT UNSIGNED NULL,                     -- NULL = sin límite
  imagen_url      VARCHAR(255) NULL,
  estado          ENUM('borrador','publicado','cancelado','finalizado') NOT NULL DEFAULT 'publicado',
  creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_evt_fecha (empresa_id, fecha_inicio),
  CONSTRAINT chk_evt_fechas CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT fk_evt_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas(id)   ON DELETE CASCADE,
  CONSTRAINT fk_evt_membresia FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Confirmar asistencia
CREATE TABLE asistencias_evento (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  evento_id        BIGINT UNSIGNED NOT NULL,
  membresia_id     BIGINT UNSIGNED NOT NULL,
  respuesta        ENUM('asistire','tal_vez','no_asistire') NOT NULL,
  fecha_respuesta  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_asistencia (evento_id, membresia_id),
  CONSTRAINT fk_asis_evento    FOREIGN KEY (evento_id)    REFERENCES eventos(id)    ON DELETE CASCADE,
  CONSTRAINT fk_asis_membresia FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. CHAT (ONE Chat) — 1 a 1 y grupos por área
-- ---------------------------------------------------------------------
CREATE TABLE conversaciones (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id  BIGINT UNSIGNED NOT NULL,
  tipo        ENUM('directa','grupo_area') NOT NULL,
  area_id     BIGINT UNSIGNED NULL,                      -- solo para grupo_area
  nombre      VARCHAR(120) NULL,
  creado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grupo_area (area_id),                    -- un grupo por área
  CONSTRAINT fk_conv_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
  CONSTRAINT fk_conv_area    FOREIGN KEY (area_id)    REFERENCES areas(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE participantes_conversacion (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id     BIGINT UNSIGNED NOT NULL,
  ultimo_leido_en  DATETIME NULL,
  unido_en         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_participante (conversacion_id, membresia_id),
  CONSTRAINT fk_part_conv      FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id) ON DELETE CASCADE,
  CONSTRAINT fk_part_membresia FOREIGN KEY (membresia_id)    REFERENCES membresias(id)     ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mensajes (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id     BIGINT UNSIGNED NOT NULL,             -- remitente
  contenido        TEXT NOT NULL,
  adjunto_url      VARCHAR(255) NULL,
  enviado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  editado_en       DATETIME NULL,
  eliminado_en     DATETIME NULL,
  KEY idx_msg_conv (conversacion_id, enviado_en),
  CONSTRAINT fk_msg_conv      FOREIGN KEY (conversacion_id) REFERENCES conversaciones(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_membresia FOREIGN KEY (membresia_id)    REFERENCES membresias(id)     ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. MARKETPLACE (productos/servicios con enlace + reclutamiento)
-- ---------------------------------------------------------------------
CREATE TABLE anuncios_marketplace (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  tipo            ENUM('producto','servicio','reclutamiento') NOT NULL,
  titulo          VARCHAR(200) NOT NULL,
  descripcion     TEXT NULL,
  enlace_url      VARCHAR(255) NULL,                     -- enlace a su sitio web
  imagen_url      VARCHAR(255) NULL,
  estado          ENUM('activo','pausado','cerrado') NOT NULL DEFAULT 'activo',
  creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_anun_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas(id)   ON DELETE CASCADE,
  CONSTRAINT fk_anun_membresia FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. NOTIFICACIONES E INTEGRACIONES (n8n)
-- ---------------------------------------------------------------------
CREATE TABLE notificaciones (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  membresia_id  BIGINT UNSIGNED NOT NULL,
  tipo          VARCHAR(50) NOT NULL,                    -- ej. nuevo_evento, nuevo_mensaje
  titulo        VARCHAR(150) NOT NULL,
  mensaje       VARCHAR(500) NULL,
  enlace        VARCHAR(255) NULL,
  canal         ENUM('app','correo','whatsapp') NOT NULL DEFAULT 'app',
  leida_en      DATETIME NULL,
  creado_en     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notif_pend (membresia_id, leida_en),
  CONSTRAINT fk_notif_membresia FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE integraciones (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id       BIGINT UNSIGNED NOT NULL,
  proveedor        ENUM('google_workspace','hubspot','whatsapp','correo','goto') NOT NULL,
  webhook_n8n_url  VARCHAR(255) NULL,
  configuracion    JSON NULL,
  activa           TINYINT(1) NOT NULL DEFAULT 1,
  creado_en        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_integracion (empresa_id, proveedor),
  CONSTRAINT fk_integ_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE registros_automatizacion (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  integracion_id  BIGINT UNSIGNED NULL,
  evento          VARCHAR(80) NOT NULL,                  -- ej. evento.creado
  estado          ENUM('pendiente','exito','error') NOT NULL DEFAULT 'pendiente',
  carga           JSON NULL,
  respuesta       TEXT NULL,
  creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_reg_estado (empresa_id, estado),
  CONSTRAINT fk_reg_empresa FOREIGN KEY (empresa_id)     REFERENCES empresas(id)      ON DELETE CASCADE,
  CONSTRAINT fk_reg_integ   FOREIGN KEY (integracion_id) REFERENCES integraciones(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. AUDITORÍA
-- ---------------------------------------------------------------------
CREATE TABLE bitacora_auditoria (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id  BIGINT UNSIGNED NULL,
  empresa_id  BIGINT UNSIGNED NULL,
  accion      VARCHAR(80) NOT NULL,                      -- ej. crear, editar, eliminar, login
  entidad     VARCHAR(60) NULL,
  entidad_id  BIGINT UNSIGNED NULL,
  detalle     JSON NULL,
  ip          VARCHAR(45) NULL,
  creado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_aud_fecha (empresa_id, creado_en),
  CONSTRAINT fk_aud_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT fk_aud_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE SET NULL
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
--  DATOS DE PRUEBA
--  Contraseña de todos los usuarios de prueba: Admin123*
-- =====================================================================
INSERT INTO usuarios (nombre, apellidos, correo, contrasena, telefono, es_admin_global) VALUES
('Admin',  'Netcloud One', 'admin@netcloudone.mx', '$2y$10$MF53CfOI9O4HBYcG55xviO23RnSkPZyu2hD8PjLDTq2zwD11dDsmC', NULL, 1),
('Laura',  'Méndez Ruiz',  'laura@demo.mx',        '$2y$10$MF53CfOI9O4HBYcG55xviO23RnSkPZyu2hD8PjLDTq2zwD11dDsmC', '5500000001', 0),
('Carlos', 'Pérez Soto',   'carlos@demo.mx',       '$2y$10$MF53CfOI9O4HBYcG55xviO23RnSkPZyu2hD8PjLDTq2zwD11dDsmC', '5500000002', 0);

INSERT INTO empresas (nombre, slug, correo_contacto, sitio_web) VALUES
('Empresa Demo', 'empresa-demo', 'contacto@demo.mx', 'https://demo.mx');

INSERT INTO configuracion_marca (empresa_id, nombre_mostrado, color_primario) VALUES
(1, 'Comunidad Demo', '#16A34A');

INSERT INTO areas (empresa_id, nombre) VALUES (1, 'Dirección'), (1, 'Ventas'), (1, 'Tecnología');

INSERT INTO membresias (usuario_id, empresa_id, area_id, rol, cargo) VALUES
(2, 1, 1, 'administrador', 'Directora'),
(3, 1, 3, 'usuario',       'Desarrollador');

INSERT INTO publicaciones (empresa_id, membresia_id, tipo, titulo, contenido) VALUES
(1, 1, 'noticia', 'Bienvenidos a Netcloud One', 'Este es el nuevo espacio de nuestra comunidad.');

INSERT INTO eventos (empresa_id, membresia_id, titulo, modalidad, enlace_virtual, fecha_inicio, fecha_fin) VALUES
(1, 1, 'Reunión de arranque', 'virtual', 'https://meet.google.com/demo', '2026-11-20 10:00:00', '2026-11-20 11:00:00');

INSERT INTO conversaciones (empresa_id, tipo, area_id, nombre) VALUES (1, 'grupo_area', 3, 'Tecnología');
INSERT INTO participantes_conversacion (conversacion_id, membresia_id) VALUES (1, 2);

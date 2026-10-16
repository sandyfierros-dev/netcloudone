-- =====================================================================
-- NETCLOUD ONE · Base de datos v4 (según diagrama ER v4)
-- Plataforma SaaS multiempresa para comunidades empresariales
-- Motor InnoDB · utf8mb4 · Compatible con XAMPP (MariaDB 10.4+) y MySQL 8.0.16+
-- Importar desde phpMyAdmin (pestaña "Importar") o:
--   mysql -u root < netcloud_one_v4.sql
-- =====================================================================

DROP DATABASE IF EXISTS netcloud_one;
CREATE DATABASE netcloud_one
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE netcloud_one;

SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================================
-- 1. NÚCLEO: usuarios y empresas
-- =====================================================================

CREATE TABLE usuarios (
  id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre                      VARCHAR(150)    NOT NULL,
  correo                      VARCHAR(255)    NOT NULL,
  contrasena                  VARCHAR(255)    NOT NULL,
  telefono                    VARCHAR(20)     NULL,
  fecha_nacimiento            DATE            NULL,
  consentimiento_whatsapp_en  DATETIME        NULL,
  estado                      ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  correo_verificado_en        DATETIME        NULL,
  es_admin_plataforma         TINYINT(1)      NOT NULL DEFAULT 0,
  creado_en                   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en                DATETIME        NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_usuarios_correo (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE empresas (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  identificador  VARCHAR(100)    NOT NULL,
  nombre         VARCHAR(150)    NOT NULL,
  estado         ENUM('activa','suspendida') NOT NULL DEFAULT 'activa',
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en   DATETIME        NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_empresas_identificador (identificador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE configuracion_empresa (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id             BIGINT UNSIGNED NOT NULL,
  zona_horaria           VARCHAR(50)     NOT NULL DEFAULT 'America/Mexico_City',
  idioma_predeterminado  VARCHAR(10)     NOT NULL DEFAULT 'es',
  formato_fecha          VARCHAR(20)     NOT NULL DEFAULT 'd/m/Y',
  otras_configuraciones  JSON            NULL,
  creado_en              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_config_empresa (empresa_id),
  CONSTRAINT fk_config_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE personalizacion_empresa (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id        BIGINT UNSIGNED NOT NULL,
  logotipo_url      VARCHAR(255)    NULL,
  color_primario    VARCHAR(7)      NOT NULL DEFAULT '#0D6EFD',
  color_secundario  VARCHAR(7)      NOT NULL DEFAULT '#6C757D',
  css_personalizado TEXT            NULL,
  fondo_login_url   VARCHAR(255)    NULL,
  creado_en         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_personalizacion_empresa (empresa_id),
  CONSTRAINT fk_personalizacion_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id) ON DELETE CASCADE,
  CONSTRAINT chk_color_primario   CHECK (color_primario   REGEXP '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT chk_color_secundario CHECK (color_secundario REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2. ESTRUCTURA ORGANIZATIVA
-- =====================================================================

CREATE TABLE departamentos (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  nombre         VARCHAR(100)    NOT NULL,
  descripcion    TEXT            NULL,
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_departamentos_empresa_nombre (empresa_id, nombre),
  CONSTRAINT fk_departamentos_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE grupos (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  nombre         VARCHAR(100)    NOT NULL,
  descripcion    TEXT            NULL,
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_grupos_empresa_nombre (empresa_id, nombre),
  CONSTRAINT fk_grupos_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE etiquetas (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  nombre         VARCHAR(100)    NOT NULL,
  color          VARCHAR(7)      NOT NULL DEFAULT '#6C757D',
  descripcion    TEXT            NULL,
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_etiquetas_empresa_nombre (empresa_id, nombre),
  CONSTRAINT fk_etiquetas_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id),
  CONSTRAINT chk_etiquetas_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE membresias (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id       BIGINT UNSIGNED NOT NULL,
  empresa_id       BIGINT UNSIGNED NOT NULL,
  departamento_id  BIGINT UNSIGNED NULL,
  rol              ENUM('admin','miembro') NOT NULL DEFAULT 'miembro',
  cargo            VARCHAR(100)    NULL,
  foto_url         VARCHAR(255)    NULL,
  biografia        TEXT            NULL,
  perfil_visible   TINYINT(1)      NOT NULL DEFAULT 1,
  estado           ENUM('pendiente','activa','desactivada') NOT NULL DEFAULT 'pendiente',
  fecha_socio      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  creado_en        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en     DATETIME        NULL,
  -- Un solo admin por empresa: columna generada con UNIQUE.
  -- Vale NULL (y por tanto no choca) salvo para el admin vigente.
  admin_unico_empresa_id BIGINT UNSIGNED
    GENERATED ALWAYS AS (
      CASE WHEN rol = 'admin' AND estado <> 'desactivada' AND eliminado_en IS NULL
           THEN empresa_id ELSE NULL END
    ) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_membresias_usuario_empresa (usuario_id, empresa_id),
  UNIQUE KEY uk_membresias_un_admin (admin_unico_empresa_id),
  KEY idx_membresias_empresa (empresa_id),
  KEY idx_membresias_departamento (departamento_id),
  CONSTRAINT fk_membresias_usuario      FOREIGN KEY (usuario_id)      REFERENCES usuarios (id),
  CONSTRAINT fk_membresias_empresa      FOREIGN KEY (empresa_id)      REFERENCES empresas (id),
  CONSTRAINT fk_membresias_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE membresias_grupos (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  membresia_id   BIGINT UNSIGNED NOT NULL,
  grupo_id       BIGINT UNSIGNED NOT NULL,
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_membresias_grupos (membresia_id, grupo_id),
  KEY idx_mg_empresa (empresa_id),
  KEY idx_mg_grupo (grupo_id),
  CONSTRAINT fk_mg_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_mg_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id) ON DELETE CASCADE,
  CONSTRAINT fk_mg_grupo     FOREIGN KEY (grupo_id)     REFERENCES grupos (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE membresias_etiquetas (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id     BIGINT UNSIGNED NOT NULL,
  membresia_id   BIGINT UNSIGNED NOT NULL,
  etiqueta_id    BIGINT UNSIGNED NOT NULL,
  creado_en      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_membresias_etiquetas (membresia_id, etiqueta_id),
  KEY idx_me_empresa (empresa_id),
  KEY idx_me_etiqueta (etiqueta_id),
  CONSTRAINT fk_me_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_me_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id) ON DELETE CASCADE,
  CONSTRAINT fk_me_etiqueta  FOREIGN KEY (etiqueta_id)  REFERENCES etiquetas (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. ACCESO: invitaciones, sesiones, auditoría
-- =====================================================================

CREATE TABLE invitaciones (
  id                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id               BIGINT UNSIGNED NOT NULL,
  invitado_por_usuario_id  BIGINT UNSIGNED NOT NULL,
  nombre                   VARCHAR(150)    NOT NULL,
  correo                   VARCHAR(255)    NOT NULL,
  rol                      ENUM('admin','miembro') NOT NULL DEFAULT 'miembro',
  token                    CHAR(64)        NOT NULL,
  estado                   ENUM('pendiente','aceptada','revocada','expirada') NOT NULL DEFAULT 'pendiente',
  expira_en                DATETIME        NOT NULL,
  aceptada_en              DATETIME        NULL,
  revocada_en              DATETIME        NULL,
  creado_en                DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_invitaciones_token (token),
  KEY idx_invitaciones_empresa_correo (empresa_id, correo),
  KEY idx_invitaciones_invitador (invitado_por_usuario_id),
  CONSTRAINT fk_invitaciones_empresa   FOREIGN KEY (empresa_id)              REFERENCES empresas (id),
  CONSTRAINT fk_invitaciones_invitador FOREIGN KEY (invitado_por_usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sesiones (
  id                VARCHAR(255)    NOT NULL,
  usuario_id        BIGINT UNSIGNED NOT NULL,
  empresa_id        BIGINT UNSIGNED NULL COMMENT 'Empresa activa de la sesión',
  direccion_ip      VARCHAR(45)     NULL,
  agente_usuario    TEXT            NULL,
  ultima_actividad  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sesiones_usuario (usuario_id),
  KEY idx_sesiones_empresa (empresa_id),
  KEY idx_sesiones_actividad (ultima_actividad),
  CONSTRAINT fk_sesiones_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_sesiones_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Solo inserción (ver triggers al final del script)
CREATE TABLE bitacora_auditoria (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT UNSIGNED NULL,
  usuario_id      BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NULL,
  accion          VARCHAR(100)    NOT NULL,
  tipo_entidad    VARCHAR(100)    NOT NULL,
  entidad_id      BIGINT UNSIGNED NOT NULL,
  direccion_ip    VARCHAR(45)     NULL,
  agente_usuario  TEXT            NULL,
  creado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_bitacora_empresa_fecha (empresa_id, creado_en),
  KEY idx_bitacora_usuario (usuario_id),
  KEY idx_bitacora_membresia (membresia_id),
  KEY idx_bitacora_entidad (tipo_entidad, entidad_id),
  CONSTRAINT fk_bitacora_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_bitacora_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuarios (id),
  CONSTRAINT fk_bitacora_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. PUBLICACIONES
-- =====================================================================

CREATE TABLE publicaciones (
  id                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id           BIGINT UNSIGNED NOT NULL,
  autor_membresia_id   BIGINT UNSIGNED NOT NULL,
  tipo                 ENUM('publicacion','comunicado') NOT NULL DEFAULT 'publicacion',
  contenido            TEXT            NOT NULL,
  visibilidad          ENUM('empresa','audiencia') NOT NULL DEFAULT 'empresa',
  estado               ENUM('publicada','oculta') NOT NULL DEFAULT 'publicada',
  editado_en           DATETIME        NULL,
  creado_en            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en         DATETIME        NULL,
  PRIMARY KEY (id),
  KEY idx_publicaciones_empresa_fecha (empresa_id, creado_en),
  KEY idx_publicaciones_autor (autor_membresia_id),
  CONSTRAINT fk_publicaciones_empresa FOREIGN KEY (empresa_id)         REFERENCES empresas (id),
  CONSTRAINT fk_publicaciones_autor   FOREIGN KEY (autor_membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE audiencias_publicacion (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id       BIGINT UNSIGNED NOT NULL,
  publicacion_id   BIGINT UNSIGNED NOT NULL,
  grupo_id         BIGINT UNSIGNED NULL,
  departamento_id  BIGINT UNSIGNED NULL,
  etiqueta_id      BIGINT UNSIGNED NULL,
  creado_en        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audiencias_empresa (empresa_id),
  KEY idx_audiencias_publicacion (publicacion_id),
  KEY idx_audiencias_grupo (grupo_id),
  KEY idx_audiencias_departamento (departamento_id),
  KEY idx_audiencias_etiqueta (etiqueta_id),
  CONSTRAINT fk_audiencias_empresa      FOREIGN KEY (empresa_id)      REFERENCES empresas (id),
  CONSTRAINT fk_audiencias_publicacion  FOREIGN KEY (publicacion_id)  REFERENCES publicaciones (id),
  CONSTRAINT fk_audiencias_grupo        FOREIGN KEY (grupo_id)        REFERENCES grupos (id),
  CONSTRAINT fk_audiencias_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos (id),
  CONSTRAINT fk_audiencias_etiqueta     FOREIGN KEY (etiqueta_id)     REFERENCES etiquetas (id),
  CONSTRAINT chk_audiencias_un_destino CHECK (
    (grupo_id IS NOT NULL) + (departamento_id IS NOT NULL) + (etiqueta_id IS NOT NULL) = 1
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE comentarios (
  id                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id           BIGINT UNSIGNED NOT NULL,
  publicacion_id       BIGINT UNSIGNED NOT NULL,
  autor_membresia_id   BIGINT UNSIGNED NOT NULL,
  contenido            TEXT            NOT NULL,
  estado               ENUM('visible','oculto') NOT NULL DEFAULT 'visible',
  editado_en           DATETIME        NULL,
  creado_en            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en         DATETIME        NULL,
  PRIMARY KEY (id),
  KEY idx_comentarios_empresa (empresa_id),
  KEY idx_comentarios_publicacion (publicacion_id, creado_en),
  KEY idx_comentarios_autor (autor_membresia_id),
  CONSTRAINT fk_comentarios_empresa     FOREIGN KEY (empresa_id)         REFERENCES empresas (id),
  CONSTRAINT fk_comentarios_publicacion FOREIGN KEY (publicacion_id)     REFERENCES publicaciones (id),
  CONSTRAINT fk_comentarios_autor       FOREIGN KEY (autor_membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reacciones_publicacion (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  publicacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  tipo            ENUM('me_gusta','me_encanta','celebrar') NOT NULL DEFAULT 'me_gusta',
  creado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_reaccion_publicacion_membresia (publicacion_id, membresia_id),
  KEY idx_reacciones_empresa (empresa_id),
  KEY idx_reacciones_membresia (membresia_id),
  CONSTRAINT fk_reacciones_empresa     FOREIGN KEY (empresa_id)     REFERENCES empresas (id),
  CONSTRAINT fk_reacciones_publicacion FOREIGN KEY (publicacion_id) REFERENCES publicaciones (id) ON DELETE CASCADE,
  CONSTRAINT fk_reacciones_membresia   FOREIGN KEY (membresia_id)   REFERENCES membresias (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5. MENSAJERÍA
-- =====================================================================

CREATE TABLE conversaciones (
  id                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id                BIGINT UNSIGNED NOT NULL,
  creada_por_membresia_id   BIGINT UNSIGNED NOT NULL,
  tipo                      ENUM('directa','canal') NOT NULL DEFAULT 'directa',
  acceso                    ENUM('abierto','cerrado') NOT NULL DEFAULT 'cerrado',
  titulo                    VARCHAR(150)    NULL,
  archivada_en              DATETIME        NULL,
  creado_en                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en              DATETIME        NULL,
  PRIMARY KEY (id),
  KEY idx_conversaciones_empresa (empresa_id),
  KEY idx_conversaciones_creador (creada_por_membresia_id),
  CONSTRAINT fk_conversaciones_empresa FOREIGN KEY (empresa_id)              REFERENCES empresas (id),
  CONSTRAINT fk_conversaciones_creador FOREIGN KEY (creada_por_membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE participantes_conversacion (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id       BIGINT UNSIGNED NOT NULL,
  conversacion_id  BIGINT UNSIGNED NOT NULL,
  membresia_id     BIGINT UNSIGNED NOT NULL,
  se_unio_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  salio_en         DATETIME        NULL,
  restringido      TINYINT(1)      NOT NULL DEFAULT 0,
  creado_en        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_participante_conv_membresia (conversacion_id, membresia_id),
  KEY idx_participantes_empresa (empresa_id),
  KEY idx_participantes_membresia (membresia_id),
  CONSTRAINT fk_participantes_empresa      FOREIGN KEY (empresa_id)      REFERENCES empresas (id),
  CONSTRAINT fk_participantes_conversacion FOREIGN KEY (conversacion_id) REFERENCES conversaciones (id) ON DELETE CASCADE,
  CONSTRAINT fk_participantes_membresia    FOREIGN KEY (membresia_id)    REFERENCES membresias (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mensajes (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id              BIGINT UNSIGNED NOT NULL,
  conversacion_id         BIGINT UNSIGNED NOT NULL,
  remitente_membresia_id  BIGINT UNSIGNED NOT NULL,
  contenido               TEXT            NULL,
  tipo_mensaje            ENUM('texto','archivo','sistema') NOT NULL DEFAULT 'texto',
  editado_en              DATETIME        NULL,
  creado_en               DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en            DATETIME        NULL,
  PRIMARY KEY (id),
  KEY idx_mensajes_empresa (empresa_id),
  KEY idx_mensajes_conversacion_fecha (conversacion_id, creado_en),
  KEY idx_mensajes_remitente (remitente_membresia_id),
  CONSTRAINT fk_mensajes_empresa      FOREIGN KEY (empresa_id)             REFERENCES empresas (id),
  CONSTRAINT fk_mensajes_conversacion FOREIGN KEY (conversacion_id)        REFERENCES conversaciones (id),
  CONSTRAINT fk_mensajes_remitente    FOREIGN KEY (remitente_membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6. MODERACIÓN
-- =====================================================================

CREATE TABLE reportes (
  id                           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id                   BIGINT UNSIGNED NOT NULL,
  reportado_por_membresia_id   BIGINT UNSIGNED NOT NULL,
  publicacion_id               BIGINT UNSIGNED NULL,
  comentario_id                BIGINT UNSIGNED NULL,
  mensaje_id                   BIGINT UNSIGNED NULL,
  motivo                       TEXT            NOT NULL,
  estado                       ENUM('pendiente','revisado','descartado') NOT NULL DEFAULT 'pendiente',
  revisado_por_membresia_id    BIGINT UNSIGNED NULL,
  revisado_en                  DATETIME        NULL,
  creado_en                    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en               DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_reportes_empresa_estado (empresa_id, estado),
  KEY idx_reportes_reportante (reportado_por_membresia_id),
  KEY idx_reportes_publicacion (publicacion_id),
  KEY idx_reportes_comentario (comentario_id),
  KEY idx_reportes_mensaje (mensaje_id),
  KEY idx_reportes_revisor (revisado_por_membresia_id),
  CONSTRAINT fk_reportes_empresa     FOREIGN KEY (empresa_id)                 REFERENCES empresas (id),
  CONSTRAINT fk_reportes_reportante  FOREIGN KEY (reportado_por_membresia_id) REFERENCES membresias (id),
  CONSTRAINT fk_reportes_publicacion FOREIGN KEY (publicacion_id)             REFERENCES publicaciones (id),
  CONSTRAINT fk_reportes_comentario  FOREIGN KEY (comentario_id)              REFERENCES comentarios (id),
  CONSTRAINT fk_reportes_mensaje     FOREIGN KEY (mensaje_id)                 REFERENCES mensajes (id),
  CONSTRAINT fk_reportes_revisor     FOREIGN KEY (revisado_por_membresia_id)  REFERENCES membresias (id),
  CONSTRAINT chk_reportes_un_objetivo CHECK (
    (publicacion_id IS NOT NULL) + (comentario_id IS NOT NULL) + (mensaje_id IS NOT NULL) = 1
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7. EVENTOS Y ARCHIVOS
-- =====================================================================

CREATE TABLE eventos (
  id                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id                BIGINT UNSIGNED NOT NULL,
  creado_por_membresia_id   BIGINT UNSIGNED NOT NULL,
  titulo                    VARCHAR(200)    NOT NULL,
  descripcion               TEXT            NULL,
  inicia_en                 DATETIME        NOT NULL,
  termina_en                DATETIME        NOT NULL,
  lugar                     VARCHAR(255)    NULL,
  cupo                      INT UNSIGNED    NULL,
  tipo                      ENUM('presencial','virtual','hibrido') NOT NULL DEFAULT 'presencial',
  estado                    ENUM('programado','cancelado','finalizado') NOT NULL DEFAULT 'programado',
  creado_en                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  eliminado_en              DATETIME        NULL,
  PRIMARY KEY (id),
  KEY idx_eventos_empresa_inicio (empresa_id, inicia_en),
  KEY idx_eventos_creador (creado_por_membresia_id),
  CONSTRAINT fk_eventos_empresa FOREIGN KEY (empresa_id)              REFERENCES empresas (id),
  CONSTRAINT fk_eventos_creador FOREIGN KEY (creado_por_membresia_id) REFERENCES membresias (id),
  CONSTRAINT chk_eventos_fechas CHECK (termina_en >= inicia_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE asistentes_evento (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  evento_id       BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  estado          ENUM('confirmado','cancelado') NOT NULL DEFAULT 'confirmado',
  registrado_en   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  creado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_asistente_evento_membresia (evento_id, membresia_id),
  KEY idx_asistentes_empresa (empresa_id),
  KEY idx_asistentes_membresia (membresia_id),
  CONSTRAINT fk_asistentes_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_asistentes_evento    FOREIGN KEY (evento_id)    REFERENCES eventos (id) ON DELETE CASCADE,
  CONSTRAINT fk_asistentes_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE archivos (
  id                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id                BIGINT UNSIGNED NOT NULL,
  subido_por_membresia_id   BIGINT UNSIGNED NOT NULL,
  mensaje_id                BIGINT UNSIGNED NULL,
  publicacion_id            BIGINT UNSIGNED NULL,
  evento_id                 BIGINT UNSIGNED NULL,
  nombre_archivo            VARCHAR(255)    NOT NULL,
  ruta_archivo              VARCHAR(500)    NOT NULL,
  tipo_archivo              VARCHAR(100)    NOT NULL,
  tamano_bytes              BIGINT UNSIGNED NOT NULL,
  creado_en                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_archivos_empresa (empresa_id),
  KEY idx_archivos_subidor (subido_por_membresia_id),
  KEY idx_archivos_mensaje (mensaje_id),
  KEY idx_archivos_publicacion (publicacion_id),
  KEY idx_archivos_evento (evento_id),
  CONSTRAINT fk_archivos_empresa     FOREIGN KEY (empresa_id)              REFERENCES empresas (id),
  CONSTRAINT fk_archivos_subidor     FOREIGN KEY (subido_por_membresia_id) REFERENCES membresias (id),
  CONSTRAINT fk_archivos_mensaje     FOREIGN KEY (mensaje_id)              REFERENCES mensajes (id),
  CONSTRAINT fk_archivos_publicacion FOREIGN KEY (publicacion_id)          REFERENCES publicaciones (id),
  CONSTRAINT fk_archivos_evento      FOREIGN KEY (evento_id)               REFERENCES eventos (id),
  CONSTRAINT chk_archivos_un_origen CHECK (
    (mensaje_id IS NOT NULL) + (publicacion_id IS NOT NULL) + (evento_id IS NOT NULL) = 1
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 8. NOTIFICACIONES E INTEGRACIONES
-- =====================================================================

CREATE TABLE preferencias_notificacion (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  canal           ENUM('correo','whatsapp') NOT NULL,
  tipo            VARCHAR(50)     NOT NULL,
  activa          TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_pref_membresia_canal_tipo (membresia_id, canal, tipo),
  KEY idx_pref_empresa (empresa_id),
  CONSTRAINT fk_pref_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_pref_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE registro_notificaciones (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT UNSIGNED NOT NULL,
  membresia_id    BIGINT UNSIGNED NOT NULL,
  tipo            VARCHAR(50)     NOT NULL,
  canal           ENUM('correo','whatsapp') NOT NULL,
  contenido       TEXT            NOT NULL,
  estado          ENUM('pendiente','enviada','fallida') NOT NULL DEFAULT 'pendiente',
  enviada_en      DATETIME        NULL,
  creado_en       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_regnot_empresa (empresa_id),
  KEY idx_regnot_membresia (membresia_id),
  KEY idx_regnot_estado (estado, canal),
  CONSTRAINT fk_regnot_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresas (id),
  CONSTRAINT fk_regnot_membresia FOREIGN KEY (membresia_id) REFERENCES membresias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE integraciones (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empresa_id              BIGINT UNSIGNED NOT NULL,
  nombre                  VARCHAR(100)    NOT NULL,
  proveedor               VARCHAR(50)     NOT NULL,
  configuracion_cifrada   TEXT            NOT NULL,
  estado                  ENUM('activa','inactiva','error') NOT NULL DEFAULT 'inactiva',
  probada_en              DATETIME        NULL,
  resultado_prueba        ENUM('exitoso','fallido') NULL,
  creado_en               DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_integraciones_empresa_proveedor (empresa_id, proveedor),
  CONSTRAINT fk_integraciones_empresa FOREIGN KEY (empresa_id) REFERENCES empresas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 9. BITÁCORA DE SOLO INSERCIÓN (impide UPDATE y DELETE)
-- =====================================================================

DELIMITER $$

CREATE TRIGGER trg_bitacora_no_update
BEFORE UPDATE ON bitacora_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'bitacora_auditoria es de solo inserción';
END$$

CREATE TRIGGER trg_bitacora_no_delete
BEFORE DELETE ON bitacora_auditoria
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'bitacora_auditoria es de solo inserción';
END$$

DELIMITER ;

-- =====================================================================
-- 10. DATOS INICIALES DE PRUEBA (opcionales; borra esta sección si no los quieres)
--     Usuario admin de plataforma: admin@netcloud.test / Admin12345!
--     (cámbiala en cuanto entres)
-- =====================================================================

INSERT INTO usuarios (nombre, correo, contrasena, estado, correo_verificado_en, es_admin_plataforma)
VALUES ('Administrador de Plataforma', 'admin@netcloud.test',
        '$2y$10$/ksiqecN3w.UYtFon4rEJ.nKv6xjy5BeSOPzbZFWSCtJflHE2k802',
        'activo', NOW(), 1);

INSERT INTO empresas (identificador, nombre) VALUES ('demo', 'Empresa Demo');

INSERT INTO configuracion_empresa (empresa_id) VALUES (1);
INSERT INTO personalizacion_empresa (empresa_id) VALUES (1);

INSERT INTO membresias (usuario_id, empresa_id, rol, estado, perfil_visible)
VALUES (1, 1, 'admin', 'activa', 1);

-- =====================================================================
-- FIN · 27 tablas
-- =====================================================================


-- =============================================
-- CREAR INDICE UNICO SI NO EXISTE
-- =============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'resumen_contribuciones_usuario'
        AND indexname = 'idx_resumen_contribuciones_usuario_id'
    ) THEN
        CREATE UNIQUE INDEX idx_resumen_contribuciones_usuario_id
        ON resumen_contribuciones_usuario(id_usuario);
    END IF;
END $$;

-- =============================================
-- ELIMINAR TODOS LOS DATOS
-- =============================================

-- Usar TRUNCATE CASCADE para eliminar TODO
TRUNCATE TABLE rutas_sugeridas RESTART IDENTITY CASCADE;
TRUNCATE TABLE lista_sitios CASCADE;
TRUNCATE TABLE listas_personalizadas CASCADE;
TRUNCATE TABLE fotografias CASCADE;
TRUNCATE TABLE seguidores CASCADE;
TRUNCATE TABLE reseñas CASCADE;
TRUNCATE TABLE sitios_turisticos RESTART IDENTITY CASCADE;
TRUNCATE TABLE usuarios RESTART IDENTITY CASCADE;

-- Resetear secuencias
DO $$
BEGIN
    -- Resetear secuencias que sabemos que existen
    ALTER SEQUENCE usuarios_id_seq RESTART WITH 1;
    ALTER SEQUENCE sitios_turisticos_id_seq RESTART WITH 1;
    ALTER SEQUENCE fotografias_id_seq RESTART WITH 1;
    ALTER SEQUENCE listas_personalizadas_id_seq RESTART WITH 1;

    -- Intentar resetear seguidores si existe
    BEGIN
        ALTER SEQUENCE seguidores_id_seq RESTART WITH 1;
    EXCEPTION
        WHEN undefined_table THEN
            NULL;
    END;

    -- Intentar resetear resenas
    BEGIN
        EXECUTE 'ALTER SEQUENCE resenas_id_seq RESTART WITH 1';
    EXCEPTION
        WHEN undefined_table THEN
            BEGIN
                EXECUTE 'ALTER SEQUENCE resenas_id_seq RESTART WITH 1';
            EXCEPTION
                WHEN undefined_table THEN
                    NULL;
            END;
    END;
END $$;


-- =============================================
-- INSERTAR USUARIOS
-- =============================================

INSERT INTO usuarios (nombre, email, contrasena_hash, biografia, fecha_registro) VALUES
('Ana Garcia', 'ana@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Viajera y fotografa. Amante de los museos y el arte.', '2024-01-15 10:30:00'),
('Bruno Diaz', 'bruno@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Entusiasta de la gastronomia. Siempre buscando el mejor restaurante.', '2024-02-20 14:15:00'),
('Carla Soto', 'carla@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Exploradora urbana. Me encantan los parques y las vistas.', '2024-03-10 09:45:00'),
('Diego Morales', 'diego@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Critico de teatro aficionado. Pasion por las artes escenicas.', '2024-04-05 16:20:00'),
('Elena Fernandez', 'elena@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Historiadora y guia turistica. Amo contar historias de Santiago.', '2024-05-12 11:00:00'),
('Felipe Torres', 'felipe@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Sommelier profesional. Experto en vinos chilenos.', '2024-06-18 13:30:00'),
('Gabriela Rojas', 'gabriela@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Arquitecta. Fascinada por los edificios historicos de la ciudad.', '2024-07-22 10:15:00'),
('Hector Vargas', 'hector@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Ciclista urbano. Descubriendo Santiago sobre dos ruedas.', '2024-08-30 15:45:00'),
('Isabel Nunez', 'isabel@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Bloguera de viajes. Compartiendo experiencias locales.', '2024-09-14 12:00:00'),
('Javier Pinto', 'javier@tbd.cl', '$2a$10$eA95nPuWcZ.TC7KA5i1OveQ/FJzUTssTaRrJbcmGzPijoIWY8F.O2', 'Estudiante de fotografia. Capturando la esencia de la ciudad.', '2024-10-01 08:30:00');


-- =============================================
-- INSERTAR SITIOS TURISTICOS
-- =============================================

ALTER TABLE sitios_turisticos ADD COLUMN IF NOT EXISTS ciudad VARCHAR(100);

INSERT INTO sitios_turisticos (nombre, descripcion, tipo, ubicacion, ciudad) VALUES
-- Parques
('Cerro San Cristobal', 'El gran parque urbano de Santiago, con vistas panoramicas.', 'Parque', ST_SetSRID(ST_MakePoint(-70.6311, -33.4197), 4326), 'Santiago'),
('Parque Forestal', 'Hermoso parque lineal a lo largo del rio Mapocho.', 'Parque', ST_SetSRID(ST_MakePoint(-70.6412, -33.4355), 4326), 'Santiago'),
('Parque Bicentenario', 'Moderno parque con lagunas artificiales y esculturas.', 'Parque', ST_SetSRID(ST_MakePoint(-70.6034, -33.3933), 4326), 'Santiago'),
('Parque Quinta Normal', 'Amplio parque con museos, lagunas y areas verdes.', 'Parque', ST_SetSRID(ST_MakePoint(-70.6828, -33.4409), 4326), 'Santiago'),

-- Museos
('Museo Nacional de Bellas Artes', 'Principal museo de arte de Chile.', 'Museo', ST_SetSRID(ST_MakePoint(-70.6435, -33.4351), 4326), 'Santiago'),
('Museo de la Memoria y los DDHH', 'Museo dedicado a la memoria historica.', 'Museo', ST_SetSRID(ST_MakePoint(-70.6795, -33.4399), 4326), 'Santiago'),
('Museo Chileno de Arte Precolombino', 'Coleccion de arte de culturas precolombinas.', 'Museo', ST_SetSRID(ST_MakePoint(-70.6523, -33.4386), 4326), 'Santiago'),
('Centro Cultural La Moneda', 'Centro cultural subterraneo con exposiciones.', 'Museo', ST_SetSRID(ST_MakePoint(-70.6538, -33.4435), 4326), 'Santiago'),

-- Teatros
('Teatro Municipal de Santiago', 'El centro cultural mas antiguo del pais.', 'Teatro', ST_SetSRID(ST_MakePoint(-70.6476, -33.4406), 4326), 'Santiago'),
('Teatro Universidad de Chile', 'Teatro historico con programacion variada.', 'Teatro', ST_SetSRID(ST_MakePoint(-70.6343, -33.4374), 4326), 'Santiago'),
('Centro Gabriela Mistral GAM', 'Moderno centro cultural con teatro y danza.', 'Teatro', ST_SetSRID(ST_MakePoint(-70.6399, -33.4389), 4326), 'Santiago'),

-- Restaurantes CERCA de teatros (<100m)
('Restaurante Make Make', 'Restaurante gourmet a pasos del Teatro Municipal.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6476, -33.4413), 4326), 'Santiago'),
('Vichuquen', 'Restaurante de comida chilena junto al Teatro Municipal.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6477, -33.4413), 4326), 'Santiago'),
('Aki Go Sushi', 'Restaurante de sushi y gohan cerca del Teatro Universidad de chile.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6340, -33.4375), 4326), 'Santiago'),

-- Otros restaurantes
('Bocanariz', 'Bar de vinos boutique con excelente gastronomia.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6412, -33.4382), 4326), 'Santiago'),
('Liguria', 'Tradicional restaurante con ambiente bohemio.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6412, -33.4344), 4326), 'Santiago'),
('Peumayen', 'Restaurante de comida ancestral chilena.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6349, -33.4325), 4326), 'Santiago'),
('Astrid y Gaston', 'Alta cocina peruana, uno de los mejores.', 'Restaurante', ST_SetSRID(ST_MakePoint(-70.6150, -33.4100), 4326), 'Santiago'),

-- Monumentos
('La Moneda', 'Palacio de gobierno, un hito historico.', 'Monumento', ST_SetSRID(ST_MakePoint(-70.6540, -33.4421), 4326), 'Santiago'),
('Plaza de Armas', 'Plaza principal de Santiago, centro historico.', 'Monumento', ST_SetSRID(ST_MakePoint(-70.6510, -33.4377), 4326), 'Santiago'),
('Catedral Metropolitana', 'Imponente catedral neoclasica.', 'Monumento', ST_SetSRID(ST_MakePoint(-70.6518, -33.4374), 4326), 'Santiago'),

-- Cafes
('Cafe Colmado', 'Cafe artesanal con excelentes pasteles.', 'Cafe', ST_SetSRID(ST_MakePoint(-70.6400, -33.4350), 4326), 'Santiago'),
('Wonderland Cafe', 'Cafe tematico con decoracion unica.', 'Cafe', ST_SetSRID(ST_MakePoint(-70.6420, -33.4378), 4326), 'Santiago'),

-- Bares
('The Clinic', 'Bar con terraza y buena seleccion de cervezas.', 'Bar', ST_SetSRID(ST_MakePoint(-70.6652, -33.4413), 4326), 'Santiago'),
('La Piojera', 'Bar tradicional, famoso por la terremoto.', 'Bar', ST_SetSRID(ST_MakePoint(-70.6520, -33.4334), 4326), 'Santiago');


-- =============================================
-- INSERTAR RESENAS (calificaciones ALTAS)
-- =============================================

DO $$
BEGIN
    -- Intentar insertar en tabla con ñ o sin ñ dinámicamente
    BEGIN
        INSERT INTO reseñas (id_usuario, id_sitio, contenido, calificacion, fecha) VALUES
        -- Ana Garcia (ID 1)
        (1, 1, 'La vista desde el Cerro San Cristobal es increible!', 5, NOW() - INTERVAL '5 days'),
        (1, 5, 'El Museo de Bellas Artes tiene una coleccion impresionante.', 5, NOW() - INTERVAL '10 days'),
        (1, 19, 'La Moneda es espectacular. El cambio de guardia es muy interesante.', 4, NOW() - INTERVAL '15 days'),
        (1, 15, 'Bocanariz tiene la mejor seleccion de vinos.', 5, NOW() - INTERVAL '7 days'),
        (1, 9, 'Asisti a una opera en el Teatro Municipal. La acustica es perfecta.', 5, NOW() - INTERVAL '20 days'),
        -- Bruno Diaz (ID 2)
        (2, 15, 'La mejor seleccion de vinos que he visto en Santiago.', 5, NOW() - INTERVAL '3 days'),
        (2, 16, 'Liguria tiene ese ambiente bohemio que me encanta.', 4, NOW() - INTERVAL '8 days'),
        (2, 17, 'Peumayen ofrece una experiencia unica.', 5, NOW() - INTERVAL '12 days'),
        (2, 18, 'Astrid y Gaston no decepciona. Alta cocina peruana.', 5, NOW() - INTERVAL '6 days'),
        (2, 22, 'Cafe Colmado tiene los mejores pasteles de la zona.', 4, NOW() - INTERVAL '2 days'),
        -- Carla Soto (ID 3)
        (3, 1, 'Perfecto para un picnic el fin de semana.', 5, NOW() - INTERVAL '4 days'),
        (3, 2, 'El Parque Forestal es ideal para caminar.', 5, NOW() - INTERVAL '9 days'),
        (3, 3, 'Parque Bicentenario es moderno y bien mantenido.', 4, NOW() - INTERVAL '14 days'),
        (3, 4, 'Quinta Normal tiene mucho espacio verde.', 4, NOW() - INTERVAL '11 days'),
        (3, 20, 'La Plaza de Armas siempre esta llena de vida.', 4, NOW() - INTERVAL '18 days'),
        -- Diego Morales (ID 4)
        (4, 9, 'El Teatro Municipal es joya arquitectonica.', 5, NOW() - INTERVAL '7 days'),
        (4, 10, 'Teatro Universidad de Chile tiene una rica historia.', 5, NOW() - INTERVAL '13 days'),
        (4, 11, 'GAM es un espacio moderno y versatil.', 5, NOW() - INTERVAL '19 days'),
        (4, 12, 'El restaurante Make Make es perfecto para comer antes de la funcion.', 4, NOW() - INTERVAL '8 days'),
        (4, 13, 'Vichuquen es un clasico santiaguino.', 4, NOW() - INTERVAL '15 days'),
        -- Elena Fernandez (ID 5)
        (5, 19, 'La Moneda tiene tanta historia. Recomiendo el tour guiado.', 5, NOW() - INTERVAL '5 days'),
        (5, 20, 'Plaza de Armas es el corazon de Santiago.', 5, NOW() - INTERVAL '10 days'),
        (5, 21, 'La Catedral Metropolitana es impresionante.', 5, NOW() - INTERVAL '15 days'),
        (5, 7, 'El Museo Precolombino tiene piezas unicas.', 5, NOW() - INTERVAL '8 days'),
        (5, 6, 'Museo de la Memoria es conmovedor y necesario.', 5, NOW() - INTERVAL '20 days'),
        -- Felipe Torres (ID 6)
        (6, 15, 'Bocanariz es mi lugar favorito. La carta de vinos es excelente.', 5, NOW() - INTERVAL '2 days'),
        (6, 17, 'Peumayen tiene un maridaje perfecto.', 5, NOW() - INTERVAL '6 days'),
        (6, 18, 'La bodega de Astrid y Gaston es impresionante.', 5, NOW() - INTERVAL '12 days'),
        (6, 12, 'El restaurante Make Make tiene una carta de vinos sorprendente.', 4, NOW() - INTERVAL '16 days'),
        -- Gabriela Rojas (ID 7)
        (7, 9, 'La arquitectura del Teatro Municipal es sublime.', 5, NOW() - INTERVAL '4 days'),
        (7, 5, 'El Palacio de Bellas Artes es una joya arquitectonica.', 5, NOW() - INTERVAL '9 days'),
        (7, 21, 'La fachada neoclasica de la Catedral es impresionante.', 5, NOW() - INTERVAL '14 days'),
        (7, 8, 'El Centro Cultural La Moneda tiene un diseno subterraneo fascinante.', 5, NOW() - INTERVAL '11 days'),
        (7, 11, 'GAM representa la arquitectura contemporanea chilena.', 5, NOW() - INTERVAL '18 days'),
        -- Hector Vargas (ID 8)
        (8, 1, 'Subir el San Cristobal en bici es un desafio.', 5, NOW() - INTERVAL '3 days'),
        (8, 2, 'Parque Forestal tiene buenas ciclovias.', 5, NOW() - INTERVAL '7 days'),
        (8, 3, 'Bicentenario es perfecto para andar en bici con la familia.', 5, NOW() - INTERVAL '13 days'),
        (8, 4, 'Quinta Normal tiene rutas ciclisticas amplias y seguras.', 4, NOW() - INTERVAL '17 days'),
        -- Isabel Nunez (ID 9)
        (9, 1, 'El Cerro San Cristobal es el mejor mirador de Santiago.', 5, NOW() - INTERVAL '1 day'),
        (9, 15, 'Bocanariz es perfecto para una cita romantica.', 5, NOW() - INTERVAL '5 days'),
        (9, 9, 'Asistir al Teatro Municipal es una experiencia de lujo.', 5, NOW() - INTERVAL '10 days'),
        (9, 22, 'Cafe Colmado es instagrameable y delicioso.', 5, NOW() - INTERVAL '3 days'),
        (9, 23, 'Wonderland Cafe tiene una decoracion de cuento.', 5, NOW() - INTERVAL '8 days'),
        -- Javier Pinto (ID 10)
        (10, 1, 'Las mejores fotos de Santiago se toman desde aqui.', 5, NOW() - INTERVAL '2 days'),
        (10, 2, 'Parque Forestal es fotogenico en cada estacion.', 5, NOW() - INTERVAL '6 days'),
        (10, 5, 'El interior del Museo de Bellas Artes es un sueno para fotografos.', 5, NOW() - INTERVAL '11 days'),
        (10, 20, 'Plaza de Armas tiene mucha vida urbana.', 5, NOW() - INTERVAL '15 days'),
        (10, 21, 'La Catedral tiene detalles arquitectonicos increibles.', 5, NOW() - INTERVAL '9 days'),
        -- Mas resenas para cafes y bares
        (2, 22, 'El cafe es excelente y los pasteles caseros son increibles.', 5, NOW() - INTERVAL '4 days'),
        (3, 23, 'Wonderland es magico, perfecto para una tarde con amigas.', 5, NOW() - INTERVAL '6 days'),
        (6, 24, 'The Clinic tiene buena seleccion de cervezas artesanales.', 4, NOW() - INTERVAL '8 days'),
        -- Mas resenas para restaurantes
        (1, 14, 'Aki Go Sushi es ideal para comer sushi', 4, NOW() - INTERVAL '12 days'),
        -- Resena antigua para consulta #7
        (1, 25, 'Experiencia autentica en La Piojera. Muy tradicional.', 3, NOW() - INTERVAL '120 days');

    EXCEPTION
        WHEN undefined_table THEN
            -- Si no existe con ñ, intentar sin ñ
            INSERT INTO reseñas (id_usuario, id_sitio, contenido, calificacion, fecha) VALUES
            (1, 1, 'La vista desde el Cerro San Cristobal es increible!', 5, NOW() - INTERVAL '5 days'),
            (1, 5, 'El Museo de Bellas Artes tiene una coleccion impresionante.', 5, NOW() - INTERVAL '10 days'),
            (1, 19, 'La Moneda es espectacular.', 4, NOW() - INTERVAL '15 days'),
            (1, 15, 'Bocanariz tiene la mejor seleccion de vinos.', 5, NOW() - INTERVAL '7 days'),
            (1, 9, 'Asisti a una opera en el Teatro Municipal.', 5, NOW() - INTERVAL '20 days'),
            (2, 15, 'La mejor seleccion de vinos que he visto.', 5, NOW() - INTERVAL '3 days'),
            (2, 16, 'Liguria tiene ese ambiente bohemio que me encanta.', 4, NOW() - INTERVAL '8 days'),
            (2, 17, 'Peumayen ofrece una experiencia unica.', 5, NOW() - INTERVAL '12 days'),
            (2, 18, 'Astrid y Gaston no decepciona.', 5, NOW() - INTERVAL '6 days'),
            (2, 22, 'Cafe Colmado tiene los mejores pasteles.', 4, NOW() - INTERVAL '2 days'),
            (3, 1, 'Perfecto para un picnic.', 5, NOW() - INTERVAL '4 days'),
            (3, 2, 'El Parque Forestal es ideal.', 5, NOW() - INTERVAL '9 days'),
            (3, 3, 'Parque Bicentenario es moderno.', 4, NOW() - INTERVAL '14 days'),
            (3, 4, 'Quinta Normal tiene mucho espacio verde.', 4, NOW() - INTERVAL '11 days'),
            (3, 20, 'La Plaza de Armas esta llena de vida.', 4, NOW() - INTERVAL '18 days'),
            (4, 9, 'El Teatro Municipal es joya arquitectonica.', 5, NOW() - INTERVAL '7 days'),
            (4, 10, 'Teatro Universidad tiene historia.', 5, NOW() - INTERVAL '13 days'),
            (4, 11, 'GAM es un espacio moderno.', 5, NOW() - INTERVAL '19 days'),
            (4, 12, 'El restaurante Make Make es perfecto.', 4, NOW() - INTERVAL '8 days'),
            (4, 13, 'Vichuquen es un clasico.', 4, NOW() - INTERVAL '15 days'),
            (5, 19, 'La Moneda tiene tanta historia.', 5, NOW() - INTERVAL '5 days'),
            (5, 20, 'Plaza de Armas es el corazon de Santiago.', 5, NOW() - INTERVAL '10 days'),
            (5, 21, 'La Catedral es impresionante.', 5, NOW() - INTERVAL '15 days'),
            (5, 7, 'El Museo Precolombino es unico.', 5, NOW() - INTERVAL '8 days'),
            (5, 6, 'Museo de la Memoria es necesario.', 5, NOW() - INTERVAL '20 days'),
            (6, 15, 'Bocanariz es mi favorito.', 5, NOW() - INTERVAL '2 days'),
            (6, 17, 'Peumayen tiene maridaje perfecto.', 5, NOW() - INTERVAL '6 days'),
            (6, 18, 'Astrid y Gaston es impresionante.', 5, NOW() - INTERVAL '12 days'),
            (6, 12, 'El restaurante Make Make tiene vinos sorprendentes.', 4, NOW() - INTERVAL '16 days'),
            (7, 9, 'Teatro Municipal es sublime.', 5, NOW() - INTERVAL '4 days'),
            (7, 5, 'Palacio de Bellas Artes es una joya.', 5, NOW() - INTERVAL '9 days'),
            (7, 21, 'La Catedral es impresionante.', 5, NOW() - INTERVAL '14 days'),
            (7, 8, 'Centro Cultural La Moneda es fascinante.', 5, NOW() - INTERVAL '11 days'),
            (7, 11, 'GAM es arquitectura contemporanea.', 5, NOW() - INTERVAL '18 days'),
            (8, 1, 'Subir en bici es un desafio.', 5, NOW() - INTERVAL '3 days'),
            (8, 2, 'Parque Forestal tiene ciclovias.', 5, NOW() - INTERVAL '7 days'),
            (8, 3, 'Bicentenario es perfecto para bici.', 5, NOW() - INTERVAL '13 days'),
            (8, 4, 'Quinta Normal tiene rutas amplias.', 4, NOW() - INTERVAL '17 days'),
            (9, 1, 'El mejor mirador de Santiago.', 5, NOW() - INTERVAL '1 day'),
            (9, 15, 'Bocanariz es perfecto para cita.', 5, NOW() - INTERVAL '5 days'),
            (9, 9, 'Teatro Municipal es experiencia de lujo.', 5, NOW() - INTERVAL '10 days'),
            (9, 22, 'Cafe Colmado es instagrameable.', 5, NOW() - INTERVAL '3 days'),
            (9, 23, 'Wonderland tiene decoracion de cuento.', 5, NOW() - INTERVAL '8 days'),
            (10, 1, 'Las mejores fotos desde aqui.', 5, NOW() - INTERVAL '2 days'),
            (10, 2, 'Parque Forestal es fotogenico.', 5, NOW() - INTERVAL '6 days'),
            (10, 5, 'Museo es sueno para fotografos.', 5, NOW() - INTERVAL '11 days'),
            (10, 20, 'Plaza de Armas tiene vida urbana.', 5, NOW() - INTERVAL '15 days'),
            (10, 21, 'La Catedral tiene detalles increibles.', 5, NOW() - INTERVAL '9 days'),
            (2, 22, 'Los pasteles son increibles.', 5, NOW() - INTERVAL '4 days'),
            (3, 23, 'Wonderland es magico.', 5, NOW() - INTERVAL '6 days'),
            (6, 24, 'The Clinic tiene cervezas artesanales.', 4, NOW() - INTERVAL '8 days'),
            (1, 14, 'Aki Go Sushi es ideal para comer sushi.', 4, NOW() - INTERVAL '12 days'),
            (1, 25, 'La Piojera es tradicional.', 3, NOW() - INTERVAL '120 days');
    END;
END $$;

INSERT INTO rutas_sugeridas (nombre, descripcion, id_usuario, camino) VALUES
(
    'Ruta Histórica Santiago Centro',
    'Un recorrido caminando desde el Bellas Artes, pasando por la Plaza de Armas hasta La Moneda.',
    5,
    ST_GeomFromText('LINESTRING(
        -70.6435 -33.4351,  
        -70.6476 -33.4406,  
        -70.6510 -33.4377,     
        -70.6540 -33.4421     
    )', 4326)
),
(
    'Circuito de Parques en Bici',
    'Ruta ideal para ciclistas conectando áreas verdes principales.',
    8, 
    ST_GeomFromText('LINESTRING(
        -70.6311 -33.4197, 
        -70.6034 -33.3933,  
        -70.6412 -33.4355   
    )', 4326)
),
(
    'Paseo Gastronómico Lastarria',
    'Breve recorrido por los mejores lugares para comer.',
    2, 
    ST_GeomFromText('LINESTRING(
        -70.6412 -33.4382,  
        -70.6412 -33.4344,  
        -70.6349 -33.4325  
    )', 4326)
);

-- =============================================
-- INSERTAR FOTOGRAFIAS
-- =============================================

INSERT INTO fotografias (id_usuario, id_sitio, url, fecha) VALUES
(1, 1, 'https://regionesdechile.cl/wp-content/uploads/2023/10/Mirador-de-La-Virgen.jpg', NOW() - INTERVAL '5 days'),
(1, 1, 'https://a.travel-assets.com/findyours-php/viewfinder/images/res70/68000/68727-San-Cristobal-Hill.jpg', NOW() - INTERVAL '5 days'),
(1, 5, 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Museo_Nacional_de_Bellas_Artes%2C_Santiago_20230311.jpg', NOW() - INTERVAL '10 days'),
(1, 9, 'https://chilecultura.gob.cl/uploads/FORMA_DE_HERRADURA.jpg', NOW() - INTERVAL '20 days'),
(1, 15, 'https://santiagochile.com/wp-content/uploads/Restaurant-BocaNariz-Santiago-Chile-10.jpg', NOW() - INTERVAL '7 days'),
(2, 15, 'https://media-front.elmostrador.cl/2016/10/bocanariz.png', NOW() - INTERVAL '3 days'),
(2, 16, 'https://www.liguria.cl/wp-content/uploads/2023/10/Pedro-de-Valdivia-scaled.jpg', NOW() - INTERVAL '8 days'),
(2, 17, 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/02/bc/12/salon-principal-borderio.jpg?w=900&h=500&s=1', NOW() - INTERVAL '12 days'),
(2, 18, 'https://www.800.cl/galeriasitios/Och/2016/7/21/Och_19577_Fl-35-AstridyGaston-Fg-2-01.jpg', NOW() - INTERVAL '6 days'),
(3, 1, 'https://assets.megamediaradios.fm/sites/3/2021/11/Cerro-San-Cristobal-1.jpg', NOW() - INTERVAL '4 days'),
(3, 2, 'https://santiagochile.com/wp-content/uploads/Parque-Forestal-Santiago-2.jpg', NOW() - INTERVAL '9 days'),
(3, 3, 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Parque_Bicentenario%2C_Vitacura%2C_Santiago_20200314_02.jpg/1280px-Parque_Bicentenario%2C_Vitacura%2C_Santiago_20200314_02.jpg', NOW() - INTERVAL '14 days'),
(3, 4, 'https://upload.wikimedia.org/wikipedia/commons/e/e9/Laguna_del_Parque_Quinta_Normal%2C_Santiago_20230520_04.jpg', NOW() - INTERVAL '11 days'),
(4, 9, 'https://upload.wikimedia.org/wikipedia/commons/c/ca/Teatro_Municipal%2C_Santiago_20230521_01.jpg', NOW() - INTERVAL '7 days'),
(4, 10, 'https://upload.wikimedia.org/wikipedia/commons/4/48/Teatro_Universidad_de_Chile%2C_Providencia%2C_Santiago_20240412.jpg', NOW() - INTERVAL '13 days'),
(4, 11, 'https://images.adsttc.com/media/images/5706/71e4/e58e/ce99/fc00/0128/large_jpg/GAM_01_Nicola%CC%81s_Saieh.jpg?1460040150', NOW() - INTERVAL '19 days'),
(5, 19, 'https://upload.wikimedia.org/wikipedia/commons/2/21/Palacio_de_La_Moneda_-_miguelreflex.jpg', NOW() - INTERVAL '5 days'),
(5, 20, 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/12/6a/a0/24/20180322-145842-largejpg.jpg?w=900&h=-1&s=1', NOW() - INTERVAL '10 days'),
(5, 21, 'https://www.uc.cl/site/assets/files/18106/catedral_stgo_istock.700x532.jpg', NOW() - INTERVAL '15 days'),
(10, 1, 'https://s3.amazonaws.com/entrekidscl/vich_files/actividadfoto/6398e83e97108527128869.png', NOW() - INTERVAL '2 days'),
(6, 12, 'https://www.800.cl/galeriasitios/Och/2022/11/18/Och__800-Mak-Make-Almacruz-2022-11-FG-lugar-F5-IMG_6309.jpg', NOW() - INTERVAL '6 days'),
(6, 13, 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/07/25/72/22/beppo-vichuquen.jpg?w=900&h=500&s=1', NOW() - INTERVAL '8 days'),
(8, 14, 'https://static.where-e.com/Chile/Santiago_Metropolitan_Region/Melipilla/Autumn-Sushi_f2528c3b8a4eccccb6696744cab2a79e.jpg', NOW() - INTERVAL '10 days'),
(10, 1, 'https://media-cdn.tripadvisor.com/media/photo-s/0e/43/e3/9d/cerro-san-cristobal.jpg', NOW() - INTERVAL '2 days'),
(10, 2, 'https://fvb.cl/wp-content/uploads/2021/02/202101_va_blogforestal-9.jpg', NOW() - INTERVAL '6 days'),
(10, 5, 'https://images.mnstatic.com/20/23/20233d12cd1eaf67bc29927b9c103dea.jpg', NOW() - INTERVAL '11 days'),
(10, 20, 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Plaza_de_Armas.JPG', NOW() - INTERVAL '15 days'),
(10, 21, 'https://images.myguide-cdn.com/md/common/large/5de3b87e37009-637280.jpg', NOW() - INTERVAL '9 days'),
(9, 1, 'https://conociendochile.cl/wp-content/uploads/2019/07/246056_1_5c2f784c32432.jpg', NOW() - INTERVAL '1 day'),
(9, 15, 'https://bocanariz.cl/wp-content/uploads/2018/03/11667548_919631058100801_7991280778859158136_n.jpg', NOW() - INTERVAL '5 days'),
(9, 9, 'https://live.staticflickr.com/6165/6183719886_9c4be80beb_b.jpg', NOW() - INTERVAL '10 days'),
(9, 22, 'https://thecitylane.com/wp-content/uploads/2018/12/IMG_6391.jpg', NOW() - INTERVAL '3 days'),
(9, 23, 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/23/90/42/2c/wonderland-cafe-rosal.jpg?w=900&h=500&s=1', NOW() - INTERVAL '8 days');


-- =============================================
-- INSERTAR SEGUIDORES
-- =============================================

INSERT INTO seguidores (id_seguidor, id_seguido, fecha_inicio) VALUES
(1, 2, '2024-02-25 10:00:00'),
(1, 3, '2024-03-15 11:30:00'),
(1, 5, '2024-05-20 14:00:00'),
(1, 9, '2024-09-20 09:00:00'),
(1, 10, '2024-10-05 16:00:00'),
(2, 6, '2024-06-25 10:00:00'),
(2, 1, '2024-03-01 12:00:00'),
(2, 9, '2024-09-25 15:00:00'),
(3, 1, '2024-04-10 10:00:00'),
(3, 8, '2024-09-05 11:00:00'),
(3, 9, '2024-10-01 14:00:00'),
(4, 1, '2024-05-01 10:00:00'),
(4, 5, '2024-06-15 12:00:00'),
(4, 7, '2024-08-01 13:00:00'),
(6, 5, '2024-07-01 10:00:00'),
(7, 5, '2024-08-15 11:00:00'),
(9, 5, '2024-10-10 12:00:00'),
(10, 5, '2024-10-20 13:00:00'),
(6, 2, '2024-07-05 10:00:00'),
(6, 1, '2024-07-10 11:00:00'),
(7, 1, '2024-08-20 10:00:00'),
(8, 3, '2024-09-10 11:00:00'),
(9, 1, '2024-09-25 12:00:00'),
(9, 10, '2024-10-15 13:00:00'),
(10, 1, '2024-10-10 14:00:00'),
(10, 9, '2024-10-20 15:00:00');


-- =============================================
-- INSERTAR LISTAS
-- =============================================

INSERT INTO listas_personalizadas (id_usuario, nombre, fecha_creacion) VALUES
(1, 'Imperdibles de Santiago', '2024-02-01 10:00:00'),
(1, 'Mis Museos Favoritos', '2024-03-15 11:00:00'),
(2, 'Tour Gastronomico', '2024-04-01 12:00:00'),
(2, 'Mejores Vinos de Santiago', '2024-05-10 13:00:00'),
(3, 'Parques para Visitar', '2024-05-20 14:00:00'),
(4, 'Teatros de Santiago', '2024-06-01 15:00:00'),
(5, 'Ruta Historica', '2024-06-15 16:00:00'),
(9, 'Para el Blog', '2024-09-20 17:00:00'),
(10, 'Fotogenico Santiago', '2024-10-05 18:00:00');

-- =============================================
-- VINCULAR SITIOS A LISTAS
-- =============================================

INSERT INTO lista_sitios (id_lista, id_sitio) VALUES
(1, 1), (1, 5), (1, 19), (1, 20), (1, 9),
(2, 5), (2, 6), (2, 7), (2, 8),
(3, 15), (3, 16), (3, 17), (3, 18),
(4, 15), (4, 17),
(5, 1), (5, 2), (5, 3), (5, 4),
(6, 9), (6, 10), (6, 11),
(7, 19), (7, 20), (7, 21), (7, 7),
(8, 1), (8, 15), (8, 9), (8, 22), (8, 23),
(9, 1), (9, 2), (9, 5), (9, 20), (9, 21);


-- =============================================
-- REFRESCAR VISTA MATERIALIZADA
-- =============================================

REFRESH MATERIALIZED VIEW CONCURRENTLY resumen_contribuciones_usuario;

-- =============================================
-- MOSTRAR USUARIOS MAS ACTIVOS
-- =============================================

SELECT
    nombre,
    total_reseñas AS reseñas,
    total_fotos AS fotos,
    total_listas AS listas,
    (total_reseñas + total_fotos + total_listas) AS total
FROM resumen_contribuciones_usuario
ORDER BY total DESC
LIMIT 10;
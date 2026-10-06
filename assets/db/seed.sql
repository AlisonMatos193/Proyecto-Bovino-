-- Datos de EJEMPLO para desarrollo (ficticios). Solo se cargan en modo debug.

INSERT INTO ganaderos (id_ganadero, nombre, rancho, telefono, municipio, updated_at) VALUES
('g-demo','Don Manuel Canul','Rancho San Isidro','9861234567','Tizimín','2026-09-23T00:00:00');

INSERT INTO bovinos (numero_siniiga, nombre, raza, sexo, categoria, proposito, peso, fecha_nacimiento, descripcion, id_ganadero, created_at, updated_at) VALUES
('0000000001','Gran Patriarca','Brahmán','M','toro_semental','Carne',980,'2016-03-10','Semental fundador con excelente conformación y temperamento dócil.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00'),
('0000000002','Dama Antigua','Brahmán','H','vaca_pegada','Carne',560,'2017-05-02','Vaca fundadora, muy buena habilidad materna.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00'),
('0000000003','Trueno','Brahmán','M','toro_semental','Carne',870,'2021-02-14','Toro joven con buen desarrollo muscular.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00'),
('0000000004','Luna','Brahmán','H','vaca_gestante','Carne',510,'2021-08-20','Hembra en programa de inseminación.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00'),
('0000000005','Estrella','Nelore','H','novilla','Carne',430,'2022-11-05','Novilla sin parentesco con el hato Brahmán.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00'),
('0000000006','Canela','Brahmán','H','novilla','Carne',445,'2022-04-18','Novilla hija de Gran Patriarca.','g-demo','2026-09-23T00:00:00','2026-09-23T00:00:00');

INSERT INTO linajes_genealogia (id_linaje, numero_siniiga, siniiga_padre, nombre_padre, siniiga_madre, nombre_madre, porcentaje_pureza, updated_at) VALUES
('l1','0000000001',NULL,NULL,NULL,NULL,100,'2026-09-23T00:00:00'),
('l2','0000000002',NULL,NULL,NULL,NULL,100,'2026-09-23T00:00:00'),
('l3','0000000003','0000000001','Gran Patriarca','0000000002','Dama Antigua',100,'2026-09-23T00:00:00'),
('l4','0000000004','0000000001','Gran Patriarca','0000000002','Dama Antigua',100,'2026-09-23T00:00:00'),
('l5','0000000005',NULL,NULL,NULL,NULL,100,'2026-09-23T00:00:00'),
('l6','0000000006','0000000001','Gran Patriarca','9999999999','Vaca externa',87.5,'2026-09-23T00:00:00');

INSERT INTO historial_clinico (id_evento, numero_siniiga, fecha, tipo_evento, protocolo_hormonal, notas, fecha_proxima, updated_at) VALUES
('e1','0000000004','2026-09-01','IATF','Protocolo de 8 días','Primer servicio del año','2026-09-30','2026-09-23T00:00:00');

INSERT INTO productos_marketplace (id_producto, numero_siniiga, tipo_venta, precio_min, precio_max, activo, updated_at) VALUES
('p1','0000000003','animal',45000,60000,1,'2026-09-23T00:00:00'),
('p2','0000000001','semen_sexado_hembra',350,500,1,'2026-09-23T00:00:00');

CREATE TABLE cliente(
	id			NUMERIC(10),
	nome		VARCHAR(50) NOT NULL,
	dtNasc		DATE NOT NULL,
	CONSTRAINT pk_cliente PRIMARY KEY (id)
);

CREATE TABLE genero(
	id			NUMERIC(10),	
	nome		VARCHAR(20) NOT NULL, 
	valorDiario	NUMERIC(10,2) NOT NULL,
	CONSTRAINT pk_genero PRIMARY KEY (id)
);

CREATE TABLE jogo(
	id 				NUMERIC(10),
	nome			VARCHAR(100) NOT NULL,
	descricao		VARCHAR(500) NOT NULL,
	anoLanc			NUMERIC(4) NOT NULL,	 
	classificacao	VARCHAR(20) NOT NULL CHECK (classificacao IN ('livre','infantil','10 ano','18 anos')),  
	situacao		VARCHAR(30) NOT NULL CHECK (situacao IN ('alugado','disponível')),
	plataforma      VARCHAR(30) NOT NULL, 
	genero			NUMERIC(10) NOT NULL,
	CONSTRAINT pk_jogo PRIMARY KEY(id),
	CONSTRAINT fk_jogo_genero FOREIGN KEY (genero) REFERENCES genero(id)
);

CREATE TABLE locacao(
	id				NUMERIC(10),	
	diarias			INTEGER NOT NULL, 
	dataLocacao		DATE NOT NULL,
	dataRetorno		DATE,
	multa			NUMERIC(10,2),	
	situacao		VARCHAR(15) NOT NULL CHECK (situacao IN('em aberto','finalizado')), 
	total			NUMERIC(10,2),
	jogo		    NUMERIC(10) NOT NULL,
	cliente			NUMERIC(10) NOT NULL,
	CONSTRAINT pk_locacao PRIMARY KEY (id),
	CONSTRAINT fk_locacao_jogo FOREIGN KEY (jogo) REFERENCES jogo(id),	
	CONSTRAINT fk_locacao_cliente FOREIGN KEY (cliente) REFERENCES cliente(id)
);

--EX1
CREATE SEQUENCE seq_cli;
CREATE SEQUENCE seq_gen;
CREATE SEQUENCE seq_jog;
CREATE SEQUENCE seq_loc;

--EX2
INSERT INTO cliente VALUES(nextval('seq_cli'),'Vinicius', '2004-02-07');
INSERT INTO cliente VALUES(nextval('seq_cli'),'Guilherme', '2004-02-02');
INSERT INTO cliente VALUES(nextval('seq_cli'),'Paloma','2003-12-28');

INSERT INTO genero VALUES(nextval('seq_gen'),'Acao',20.00);
INSERT INTO genero VALUES(nextval('seq_gen'),'Aventura', 30.00);
INSERT INTO genero VALUES(nextval('seq_gen'),'Terror', 35.00);

INSERT INTO jogo VALUES(nextval('seq_jog'),'call of duty','jogo de tiro',2018, '10 ano', 'alugado', 'Ps2',
(SELECT id FROM genero WHERE nome='Acao'));
INSERT INTO jogo VALUES(nextval('seq_jog'),'TINTIN','jogo de tiro',2018, '18 anos', 'disponível', 'Ps5',
(SELECT id FROM genero WHERE nome='Aventura'));
INSERT INTO jogo VALUES(nextval('seq_jog'),'medo','jogo de tiro',2022, '10 ano', 'alugado', 'Ps4',
(SELECT id FROM genero WHERE nome='Terror'));

INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-10','2022-05-20',5.00,'finalizado',20.00,
     (SELECT id FROM jogo WHERE nome= 'call of duty'), 
     (SELECT id FROM cliente WHERE nome= 'Vinicius'));
INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-12','2022-05-25',5.00,'finalizado',30.00,
     (SELECT id FROM jogo WHERE nome= 'TINTIN'), 
     (SELECT id FROM cliente WHERE nome= 'Guilherme'));
INSERT INTO locacao VALUES (nextval('seq_loc'),10, '2022-05-10','2022-05-20',5.00,'finalizado',35.00,
     (SELECT id FROM jogo WHERE nome= 'medo'), 
     (SELECT id FROM cliente WHERE nome= 'Paloma'));
	 
CREATE FUNCTION locacao_jg(NUMERIC,INTEGER,DATE,DATE,NUMERIC,VARCHAR,NUMERIC,NUMERIC,NUMERIC) RETURNS void AS 
$$ 
   INSERT INTO locacao VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9);
$$ LANGUAGE sql;

SELECT * FROM locacao_jg(nextval('seq_loc'),6,'2022-11-23',NULL,0.00,'em aberto',NULL,
						(SELECT id FROM jogo WHERE nome = 'call of duty'),
						(SELECT id FROM cliente WHERE nome = 'Vinicius')
						);

CREATE FUNCTION devolucao_jog(DATE,NUMERIC,VARCHAR,NUMERIC,DATE,NUMERIC) RETURNS void AS 
$$ 
  UPDATE locacao
  SET dataRetorno = $1, multa = $2, situacao = $3, total = $4
  WHERE dataLocacao = $5 AND cliente = $6
$$ LANGUAGE 'sql';

CREATE VIEW jogos_alugados (jogo, quantidade) AS 
SELECT jogo.nome, count(l.id)
FROM jogo 
INNER JOIN locacao l ON jogo.id = l.jogo
GROUP BY jogo.nome;

CREATE SEQUENCE seq_loc_log;

CREATE TABLE locacao_log(
id INTEGER DEFAULT(nextval('seq_loc_log')),
	id_registro INTEGER,
	usuario VARCHAR(50) NOT NULL, 
	data_acao TIMESTAMP,
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION loc_log() RETURNS TRIGGER AS 
$$
   BEGIN
        INSERT INTO locacao_log (id_registro, usuario, data_acao, acao) VALUES (OLD.id, current_user, now(),'Delete');
		RETURN OLD;
   END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_log BEFORE DELETE ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log();

--INSERT--
CREATE SEQUENCE seq_loc_log2;
CREATE TABLE locacao_log2(
id INTEGER DEFAULT(nextval('seq_loc_log2')),
	id_registro INTEGER,
	usuario VARCHAR(50) NOT NULL,
	data_acao TIMESTAMP,
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log2 PRIMARY KEY (id)
);
CREATE OR REPLACE FUNCTION loc_log2() RETURNS TRIGGER AS 
$$
  BEGIN
  INSERT INTO locaco_log2 (id_registro, usuario, data_acao, acao) VALUES (new.id, current_user, now(), 'Insert');
  RETURN NEW;
  END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER insert_log BEFORE INSERT ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log2();

INSERT INTO locacao VALUES (nextval('seq_loc'), 4, '2022-11-19', '2022-11-22', 1.00, 'finalizado', 0.50, 
						   (SELECT id FROM jogo WHERE nome = 'TINTIN'),
							(SELECT id From cliente WHERE nome = 'Guilherme')
						   );
--UPDATE--
CREATE SEQUENCE seq_loc_log3;
CREATE TABLE loc_log3(
id INTEGER DEFAULT(nextval('seq_loc_log3')),
	id_registro INTEGER, 
	usuario VARCHAR(10) NOT NULL, 
	data_acao TIMESTAMP, 
	acao VARCHAR(10),
	CONSTRAINT pk_loc_log3 PRIMARY KEY (id)
);

CREATE OR REPLACE FUNCTION loc_log3() RETURNS TRIGGER AS 
$$
   BEGIN
   INSERT INTO loc_log3(id_registro, usuario, data_acao, acao) VALUES (new.id, current_user, now(), 'Update');
   RETURN NEW;
   END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER insert_log BEFORE UPDATE ON locacao FOR EACH ROW EXECUTE PROCEDURE loc_log3();

UPDATE locacao SET total=20.00 WHERE dataLocacao = '2022-11-23' AND cliente = 1
CREATE TABLE sql_table_a (
    ID          INT NOT NULL,
    FIRST_NAME  VARCHAR(255),
    LAST_NAME   VARCHAR(255),
    PRIMARY KEY (ID)
);

CREATE TABLE sql_table_b (
    ID          INT NOT NULL,
    DEPT        VARCHAR(255),
    LAST_NAME   VARCHAR(255),
    PRIMARY KEY (ID)
);

INSERT INTO sql_table_a (ID, FIRST_NAME, LAST_NAME) VALUES
(1, 'John', 'Snow'),
(2, 'Mike', 'Tyson'),
(3, 'Michael', 'Keaton'),
(4, 'Freddie', 'Mercury'),
(5, 'Steve', 'Jobs'),
(6, 'Johnny', 'Depp');

INSERT INTO sql_table_b (ID, DEPT, FIRST_NAME) VALUES
(1, 'Security', 'John'),
(2, 'Security', 'Mike'),
(3, 'Production', 'Michael'),
(4, 'Arts', 'Freddie'),
(5, 'IT', 'Steve'),
(6, 'Production', 'Johnny');

SELECT a.ID, a.FIRST_NAME, b.DEPT FROM sql_table_a a
LEFT JOIN sql_table_b b
ON a.FIRST_NAME = b.FIRST_NAME;

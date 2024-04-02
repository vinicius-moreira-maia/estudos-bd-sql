import psycopg2
import hidden
import time

# base é o nome do arquivo para a criação da tabela (sem o .txt)
base = "pg19337.txt".split('.')[0]

# abrindo o txt do livro
fhand = open("PG4E/projeto_livro/pg19337.txt", "r")

# credenciais
secrets = hidden.secrets()

# estabelecendo conexão com o servidor
conn = psycopg2.connect(host=secrets['host'], port=secrets['port'],
        database=secrets['database'], 
        user=secrets['user'], 
        password=secrets['pass'], 
        connect_timeout=3)

# criando cursor
cur = conn.cursor()

# criação da tabela que terá como nome o nome do próprio arquivo
sql = 'DROP TABLE IF EXISTS '+base+' CASCADE;'
print(sql)
cur.execute(sql)
sql = 'CREATE TABLE '+base+' (id SERIAL, body TEXT);'
print(sql)
cur.execute(sql)

para = ''
chars = 0
count = 0
pcount = 0

for line in fhand:
    count = count + 1
    line = line.strip()
    chars = chars + len(line)

    if line == '' and para == '' : continue
    
    if line == '' :
        sql = 'INSERT INTO '+base+' (body) VALUES (%s);'

        cur.execute(sql, (para, ))
        
        pcount = pcount + 1
        
        if pcount % 50 == 0 : conn.commit()

        if pcount % 100 == 0 : 
            print(pcount, 'loaded...')
            time.sleep(1)

        para = ''
        continue

    para = para + ' ' + line

conn.commit()
cur.close()

print(' ')
print('Loaded',pcount,'paragraphs',count,'lines',chars,'characters')


# criando índice GIN na coluna 'body' da tabela, usando ts_vector (vetor textual)
# executar no psql, tanto a criação do índice como as consultas
sql = "CREATE INDEX TABLE_gin ON TABLE USING gin(to_tsvector('english', body));"
sql = sql.replace('TABLE', base)
print(' ')
print('Run this manually to make your index:')
print(sql)

# SELECT body FROM pg19337  WHERE to_tsquery('english', 'goose') @@ to_tsvector('english', body) LIMIT 5;
# EXPLAIN ANALYZE SELECT body FROM pg19337  WHERE to_tsquery('english', 'goose') @@ to_tsvector('english', body);

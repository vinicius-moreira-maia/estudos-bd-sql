import psycopg2
import hidden

# carregando as credenciais
secrets = hidden.secrets()

# conexão com o servidor, enviando as credenciais
conexao = psycopg2.connect(host = secrets['host'],
                           port = secrets['port'],
                           database = secrets['database'], 
                           user = secrets['user'], 
                           password = secrets['pass'], 
                           connect_timeout = 3)

# cursor é o objeto que uso para enviar comandos para o servidor de bd
cursor_ = conexao.cursor()

sql = 'DROP TABLE IF EXISTS pythonfun CASCADE;'
print(sql)
cursor_.execute(sql)

sql = 'CREATE TABLE pythonfun (id SERIAL, line TEXT);'
print(sql)
cursor_.execute(sql)

# enviando os comandos para o servidor de postgres 
conexao.commit() 

# inserindo dados
for i in range(10) : 
    txt = "Have a nice day "+str(i)
    sql = 'INSERT INTO pythonfun (line) VALUES (%s);' # %s é placeholder para strings
    cursor_.execute(sql, (txt, ))

conexao.commit()

#sql = "SELECT id, line FROM pythonfun WHERE id=5;" 
sql = "SELECT * FROM pythonfun;" 
print(sql)
cursor_.execute(sql)

# fetchone retorna as linhas da tabela, uma após a outra, até que o retorno seja None
# a cada chamado, a próxima linha da tabela será retornada 
linha = cursor_.fetchone()

# em algum momento 'linha' vai ser False(None)
while linha:
    print(linha)
    linha = cursor_.fetchone()

'''
if linha is None : 
    print('Linha não encontrada')
else:
    print('Linha encontrada', linha)
'''

# RETURNING retorna o que se pede, que no caso é o id
# RETURNING geralmente é usado com UPDATE, INSERT e DELETE
#sql = 'INSERT INTO pythonfun (line) VALUES (%s) RETURNING id;' -> o fetchone logo após esse insert retornaria apenas o id mesmo
sql = 'INSERT INTO pythonfun (line) VALUES (%s) RETURNING *;' # -> retorna toda a linha agora
cursor_.execute(sql, (txt, ))

id = cursor_.fetchone() # o id é o primeiro elemento da tupla
print('Nova linha', id)

# ERRO, não há coluna mistake
#sql = "SELECT line FROM pythonfun WHERE mistake=5;"
#print(sql)
#cursor_.execute(sql)

conexao.commit()
cursor_.close()

import psycopg2
import hidden
import requests
import sys

# some texts are in portuguese =)

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

sql = 'DROP TABLE IF EXISTS pokeapi;'
print(sql)
cursor_.execute(sql)

sql = 'CREATE TABLE IF NOT EXISTS pokeapi (id INTEGER, body JSONB);'
print(sql)
cursor_.execute(sql)

conexao.commit()

for i in range(1, 101):
    try:
        url = f"https://pokeapi.co/api/v2/pokemon/{i}"
        response = requests.get(url)
        text = response.text

        sql = 'INSERT INTO pokeapi (body) VALUES (%s);'
        cursor_.execute(sql, (text, ))

    except:   
        sys.exit("erro na requisição dos dados")

conexao.commit()
cursor_.close()



# Elastic Search é APENAS um REST webservice

# pip install elasticsearch
# pip3 install --user 'elasticsearch<7.14.0'

# Digitar na CLI
# wget https://www.pg4e.com/code/elasticbook.py
# wget https://www.pg4e.com/code/hidden-dist.py
# wget http://www.gutenberg.org/cache/epub/18866/pg18866.txt

from elasticsearch import Elasticsearch, RequestsHttpConnection
import time
import copy
import hidden
import uuid
import json
import hashlib

bookfile = input("Digite o nome do arquivo do livro: ")
if bookfile.strip() == '':
    bookfile = "pg22381.txt"

# abrindo o arquivo do livro
fhand = open(bookfile)

# carregando credenciais
secrets = hidden.elastic()

# criando uma instância do elastic search
es = Elasticsearch(
    [ secrets['host'] ],
    http_auth=(secrets['user'], secrets['pass']),
    url_prefix = secrets['prefix'],
    scheme=secrets['scheme'],
    port=secrets['port'],
    connection_class=RequestsHttpConnection,
)

# o nome do índice ("tabela") será o próprio nome de usuário
indexname = secrets['user']

# deletando o índice ("tabela") como se fosse um 'DROP INDEX' (caso já exista)
res = es.indices.delete(index=indexname, ignore=[400, 404])
print("Dropped index", indexname)
print(res)

# criando novo índice ("tabela") como se fosse um 'CREATE INDEX'
res = es.indices.create(index=indexname)
print("Created the index...")
print(res)

para = ''
chars = 0
count = 0
pcount = 0

for line in fhand:
    count = count + 1
    line = line.strip()
    chars = chars + len(line)

    if line == '' and para == '' : 
        continue

    if line == '' :
        pcount = pcount + 1

        # dicionário do parágrafo com o texto do parágrafo e o número do parágrafo
        doc = {
            'offset' : pcount,
            'content': para
        }

        # Usando a contagem dos parágrafos como chave primária
        # pkey = pcount

        # usando GUID como chave primária (números aleatórios)
        # pkey = uuid.uuid4()

        # usando uma hash SHA256 do documento todo (parágrafo) como chave primária
        m = hashlib.sha256()
        m.update(json.dumps(doc).encode())
        pkey = m.hexdigest()

        res = es.index(index=indexname, id=pkey, body=doc)

        print('Added document', pkey)
        # print(res['result'])

        if pcount % 100 == 0 :
            print(pcount, 'loaded...')
            time.sleep(1)

        para = ''
        continue

    para = para + ' ' + line

# É necessário atualizar o índice para que ele esteja imediatamente disponível para consulta após sua criação
# o elasticsearch não os disponibiliza automaticamente, há um delay (ele faz automaticamente, mas não é imediato)
res = es.indices.refresh(index=indexname)
print("Index refreshed", indexname)
print(res)

print(' ')
print('Loaded',pcount,'paragraphs',count,'lines',chars,'characters')



from datetime import datetime
from elasticsearch import Elasticsearch
from elasticsearch import RequestsHttpConnection

import hidden

# --> Elasticsearch é um banco distribuído acessível via REST APIs (é um webservice)
# --> Sendo um webservice posso simplesmente usar a lib requests, mas a lib do elastic abstrai muita coisa

# carregando as credenciais
secrets = hidden.elastic()

# criando instância do elasticsearch
es = Elasticsearch(
    [secrets['host']],
    http_auth=(secrets['user'], secrets['pass']),
    url_prefix = secrets['prefix'],
    scheme=secrets['scheme'],
    port=secrets['port'],
    connection_class=RequestsHttpConnection,
)

# nome do índice ("tabela") é o nome do usuário
indexname = secrets['user']

# deletando índice caso exista
res = es.indices.delete(index=indexname, ignore=[400, 404])
print("Índice deletado")
print(res)

# criando novo índice
res = es.indices.create(index=indexname)
print("Índice criado")
print(res)

# documento a ser inserido no banco de dados
doc = {
    'author': 'kimchy',
    'type' : 'tweet',
    'text': '''The word counting program above directly uses all of these patterns
What could possibly go wrong
As we saw in our earliest conversations with Python we must communicate
very precisely when we write Python code The smallest deviation or
mistake will cause Python to give up looking at your program''',
    'timestamp': datetime.now(),
}

# inserindo o documento (forneço nome do índice ("tabela"), id (chave primária) e corpo)
# não alterar tipo da chave após a criação!
res = es.index(index=indexname, id='abc', body=doc)
print('Documento adicionado...')
print(res['result'])

# consultando documento, forneço o nome do índice e a chave primária
res = es.get(index=indexname, id='abc')
print('Documento recuperado...')
print(res)

# refresh força a atualização do índice para que consultas possam ser feitas logo em seguida
res = es.indices.refresh(index=indexname)
print("Index refreshed")
print(res)

# Lendo documentos filtrando os resultados...
# https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
x = {
  "query": {
    "bool": {
      "must": {
        "match": {
          "text": "bonsai"
        }
      },
      "filter": {
        "match": {
          "type": "tweet" 
        }
      }
    }
  }
}

res = es.search(index=indexname, body=x)
print('Search results...')
print(res)
print()
print("Got %d Hits:" % len(res['hits']['hits']))
for hit in res['hits']['hits']:
    s = hit['_source']
    print(f"{s['timestamp']} {s['author']}: {s['text']}")



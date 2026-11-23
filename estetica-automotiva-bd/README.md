# Sistema de Gestão para Estética Automotiva

Trabalho Final – Modelagem de Banco de Dados Completa (2º Bimestre).
Banco de dados modelado e implementado em **PostgreSQL no Supabase**.

> **Aluno(a):** Cleiton Cesar Ferreira

## Cenário

### Descrição da empresa

A empresa é uma estética automotiva de pequeno porte que atende clientes particulares com serviços como lavagem, polimento, vitrificação de pintura, higienização interna, hidratação de couro, cristalização de vidros, aplicação de películas de proteção e coating cerâmico. Os atendimentos são executados por uma equipe de funcionários (lavadores, polidores, detalhistas e atendentes) e consomem produtos e insumos (shampoos, ceras, vitrificadores, microfibras, boinas de espuma etc.) comprados de fornecedores.

### Problema

Hoje o controle da empresa é feito de forma manual, em cadernos e planilhas, o que causa:

- erros de orçamento e de cobrança dos serviços;
- falta de produtos no estoque no momento do atendimento;
- dificuldade para consultar o histórico de serviços de cada cliente e de cada veículo;
- falta de informação sobre o desempenho da equipe e sobre os serviços mais realizados.

### Necessidade

O sistema deve centralizar o cadastro de clientes e veículos, registrar cada ordem de serviço (OS) com os serviços realizados, controlar o consumo de produtos e o estoque, e registrar o pagamento de cada atendimento.

### Regras de negócio

- Um cliente pode ter vários veículos; cada veículo pertence a um único cliente.
- Cada OS é aberta para um único veículo e tem um funcionário responsável pela execução.
- Uma OS pode conter vários serviços, e um serviço pode aparecer em várias OS (com a quantidade e o preço cobrado no momento).
- Cada serviço consome produtos (insumos) em quantidades definidas, e cada produto pode ser usado em vários serviços.
- Cada produto é fornecido por um fornecedor; um fornecedor pode fornecer vários produtos.
- Cada OS pode possuir no máximo um pagamento, e cada pagamento pertence a uma única OS (relacionamento 0:1 do lado da OS e 1:1 do lado do pagamento).
- O valor total da OS é a soma de (quantidade × preço cobrado) de seus serviços.
- A data de conclusão da OS nunca pode ser anterior à data de abertura.

### Entidades, atributos e relacionamentos

O modelo possui **8 entidades**: Cliente, Veículo, Funcionário, Fornecedor, Produto, Serviço, Ordem de Serviço e Pagamento.

| Tipo de atributo | Onde aparece |
|---|---|
| Simples | nome, cpf, placa, marca, modelo, preço, quantidade, status etc. |
| Composto | endereço do cliente (rua, número, bairro, cidade, UF e CEP) |
| Multivalorado | telefone do cliente (um cliente pode ter vários telefones) |
| Derivado | valor_total da OS (soma dos serviços) e tempo_de_casa do funcionário (a partir da data de admissão) |
| Chave primária | um identificador (id_...) em cada entidade |

| Tipo de relacionamento | Onde aparece |
|---|---|
| 1:1 | Ordem de Serviço – Pagamento |
| 1:N | Cliente – Veículo; Veículo – Ordem de Serviço; Funcionário – Ordem de Serviço; Fornecedor – Produto |
| N:N | Ordem de Serviço – Serviço; Serviço – Produto |

## Modelagem Conceitual

O Diagrama Entidade-Relacionamento (DER) foi feito na notação de Chen.

![DER – Estética Automotiva](imagens/der.png)

### Entidades e atributos

| Entidade | Atributos |
|---|---|
| Cliente | **id_cliente** (PK), nome, cpf, email, data_cadastro, endereço (composto: rua, número, bairro, cidade, UF, CEP), telefone (multivalorado) |
| Veículo | **id_veiculo** (PK), placa, marca, modelo, ano, cor, tipo |
| Funcionário | **id_funcionario** (PK), nome, cpf, cargo, data_admissao, salario, tempo_de_casa (derivado) |
| Fornecedor | **id_fornecedor** (PK), razao_social, cnpj, email, telefone |
| Produto | **id_produto** (PK), nome, marca, unidade, preco_custo, quantidade_estoque, estoque_minimo |
| Serviço | **id_servico** (PK), nome, descricao, preco_base, duracao_estimada_min |
| Ordem de Serviço | **id_os** (PK), data_abertura, data_conclusao, status, observacoes, valor_total (derivado) |
| Pagamento | **id_pagamento** (PK), forma_pagamento, valor_pago, data_pagamento |

### Relacionamentos e cardinalidades

| Entidade A | Relacionamento | Entidade B | Cardinalidades (mín, máx) | Tipo |
|---|---|---|---|---|
| Cliente | possui | Veículo | Cliente (0,N) – Veículo (1,1) | 1:N |
| Veículo | recebe | Ordem de Serviço | Veículo (0,N) – OS (1,1) | 1:N |
| Funcionário | executa | Ordem de Serviço | Funcionário (0,N) – OS (1,1) | 1:N |
| Fornecedor | fornece | Produto | Fornecedor (0,N) – Produto (1,1) | 1:N |
| Ordem de Serviço | é paga por | Pagamento | OS (0,1) – Pagamento (1,1) | 1:1 |
| Ordem de Serviço | contém | Serviço | OS (1,N) – Serviço (0,N) | N:N |
| Serviço | consome | Produto | Serviço (0,N) – Produto (0,N) | N:N |

Atributos dos relacionamentos N:N: **contém** (quantidade, preco_cobrado) e **consome** (quantidade_usada).

## Modelagem Lógica

O DER foi convertido em um modelo relacional com **11 tabelas**. Regras aplicadas:

- atributo composto (endereço): colunas separadas na tabela `cliente`;
- atributo multivalorado (telefone): tabela `telefone_cliente`, ligada ao cliente por chave estrangeira;
- atributo derivado (valor_total): não vira coluna, é calculado pela view `vw_os_valor_total`; o tempo de casa também é calculado em consulta, a partir de `data_admissao`;
- relacionamento 1:N: chave estrangeira na tabela do lado "N";
- relacionamento 1:1: chave estrangeira em `pagamento` com restrição `UNIQUE`;
- relacionamento N:N: tabela associativa com chave primária composta.

### cliente

| Coluna | Tipo | Restrições |
|---|---|---|
| id_cliente | INT | PK (automático) |
| nome | VARCHAR(100) | NOT NULL |
| cpf | CHAR(11) | NOT NULL, UNIQUE, 11 dígitos |
| email | VARCHAR(100) |  |
| data_cadastro | DATE | NOT NULL, padrão: data atual |
| rua | VARCHAR(100) | endereço (composto) |
| numero | VARCHAR(10) | endereço (composto) |
| bairro | VARCHAR(60) | endereço (composto) |
| cidade | VARCHAR(60) | endereço (composto) |
| uf | CHAR(2) | duas letras maiúsculas |
| cep | CHAR(8) |  |

### telefone_cliente

| Coluna | Tipo | Restrições |
|---|---|---|
| id_telefone | INT | PK |
| id_cliente | INT | **FK** → cliente, NOT NULL |
| numero | VARCHAR(15) | NOT NULL |

### veiculo

| Coluna | Tipo | Restrições |
|---|---|---|
| id_veiculo | INT | PK |
| id_cliente | INT | **FK** → cliente, NOT NULL |
| placa | VARCHAR(8) | NOT NULL, UNIQUE |
| marca | VARCHAR(40) | NOT NULL |
| modelo | VARCHAR(60) | NOT NULL |
| ano | INT | entre 1950 e 2100 |
| cor | VARCHAR(30) |  |
| tipo | VARCHAR(10) | NOT NULL: carro ou moto |

### funcionario

| Coluna | Tipo | Restrições |
|---|---|---|
| id_funcionario | INT | PK |
| nome | VARCHAR(100) | NOT NULL |
| cpf | CHAR(11) | NOT NULL, UNIQUE |
| cargo | VARCHAR(50) | NOT NULL |
| data_admissao | DATE | NOT NULL |
| salario | DECIMAL(10,2) | NOT NULL, > 0 |

### fornecedor

| Coluna | Tipo | Restrições |
|---|---|---|
| id_fornecedor | INT | PK |
| razao_social | VARCHAR(120) | NOT NULL |
| cnpj | CHAR(14) | NOT NULL, UNIQUE, 14 dígitos |
| email | VARCHAR(100) |  |
| telefone | VARCHAR(15) |  |

### produto

| Coluna | Tipo | Restrições |
|---|---|---|
| id_produto | INT | PK |
| id_fornecedor | INT | **FK** → fornecedor, NOT NULL |
| nome | VARCHAR(100) | NOT NULL |
| marca | VARCHAR(50) |  |
| unidade | VARCHAR(10) | NOT NULL, padrão 'un' |
| preco_custo | DECIMAL(10,2) | NOT NULL, >= 0 |
| quantidade_estoque | INT | NOT NULL, >= 0 |
| estoque_minimo | INT | NOT NULL, >= 0 |

### servico

| Coluna | Tipo | Restrições |
|---|---|---|
| id_servico | INT | PK |
| nome | VARCHAR(100) | NOT NULL |
| descricao | TEXT |  |
| preco_base | DECIMAL(10,2) | NOT NULL, >= 0 |
| duracao_estimada_min | INT | NOT NULL, > 0 |

### ordem_servico

| Coluna | Tipo | Restrições |
|---|---|---|
| id_os | INT | PK |
| id_veiculo | INT | **FK** → veiculo, NOT NULL |
| id_funcionario | INT | **FK** → funcionario, NOT NULL |
| data_abertura | DATE | NOT NULL, padrão: data atual |
| data_conclusao | DATE | deve ser >= data_abertura |
| status | VARCHAR(20) | NOT NULL: aberta, em andamento, concluída ou cancelada |
| observacoes | TEXT |  |

### pagamento

| Coluna | Tipo | Restrições |
|---|---|---|
| id_pagamento | INT | PK |
| id_os | INT | **FK** → ordem_servico, NOT NULL, **UNIQUE** (garante o 1:1) |
| forma_pagamento | VARCHAR(20) | NOT NULL: dinheiro, pix, cartão débito ou cartão crédito |
| valor_pago | DECIMAL(10,2) | NOT NULL, > 0 |
| data_pagamento | DATE | NOT NULL, padrão: data atual |

### os_servico (N:N)

| Coluna | Tipo | Restrições |
|---|---|---|
| id_os | INT | PK composta, **FK** → ordem_servico |
| id_servico | INT | PK composta, **FK** → servico |
| quantidade | INT | NOT NULL, > 0 |
| preco_cobrado | DECIMAL(10,2) | NOT NULL, >= 0 |

### servico_produto (N:N)

| Coluna | Tipo | Restrições |
|---|---|---|
| id_servico | INT | PK composta, **FK** → servico |
| id_produto | INT | PK composta, **FK** → produto |
| quantidade_usada | DECIMAL(10,2) | NOT NULL, > 0 |

### Como as tabelas se relacionam

| Tabela filha | Chave estrangeira | Tabela pai | Tipo | ON DELETE |
|---|---|---|---|---|
| telefone_cliente | id_cliente | cliente | 1:N | CASCADE |
| veiculo | id_cliente | cliente | 1:N | RESTRICT |
| produto | id_fornecedor | fornecedor | 1:N | RESTRICT |
| ordem_servico | id_veiculo | veiculo | 1:N | RESTRICT |
| ordem_servico | id_funcionario | funcionario | 1:N | RESTRICT |
| pagamento | id_os | ordem_servico | 1:1 | CASCADE |
| os_servico | id_os | ordem_servico | N:N | CASCADE |
| os_servico | id_servico | servico | N:N | RESTRICT |
| servico_produto | id_servico | servico | N:N | CASCADE |
| servico_produto | id_produto | produto | N:N | RESTRICT |

O cliente de uma OS é obtido pelo veículo (`ordem_servico → veiculo → cliente`), evitando que uma OS aponte para um cliente diferente do dono do veículo.

## Modelagem Física

O modelo lógico foi implementado no Supabase (PostgreSQL) com o script [`sql/01_schema.sql`](sql/01_schema.sql).

- Chaves primárias automáticas (`GENERATED ALWAYS AS IDENTITY`).
- Integridade referencial com `FOREIGN KEY` e `ON DELETE` definido em todas as relações.
- Restrições `CHECK`, `UNIQUE` e `NOT NULL` (CPF, CNPJ, UF, status, forma de pagamento, valores positivos, datas).
- Índices nas chaves estrangeiras.
- View `vw_os_valor_total` para o atributo derivado.
- Row Level Security habilitado nas tabelas.

### Evidências do Supabase

As capturas de tela foram mantidas fora do DOCX para evitar um arquivo excessivamente grande. Todas as evidências ficam organizadas no GitHub, na [pasta de prints da implementação física](prints/fisico/).

**Tabelas criadas**

[Visualizar Tabelas.PNG ](prints/fisico/Tabelas.PNG)

**Estrutura da tabela cliente**

[Visualizar Tabela 1.PNG ](prints/fisico/Tabela 1.PNG)

**Estrutura da tabela ordem_servico**

[Visualizar Tabela 2.PNG ](prints/fisico/Tabela 2.PNG)

## Dados

O banco foi populado com dados fictícios e coerentes com o cenário pelo script [`sql/02_dados.sql`](sql/02_dados.sql), que usa `generate_series` e valores calculados a partir do índice (rodar de novo gera os mesmos dados).

| Tabela | Registros |
|---|---|
| cliente, telefone_cliente, veiculo, funcionario, fornecedor, produto, servico, ordem_servico, pagamento | 500 em cada tabela |
| os_servico | 1.001 |
| servico_produto | 1.001 |

Regras de negócio refletidas nos dados:

- nomes de clientes e funcionários não se repetem; CPF, CNPJ e placa são únicos;
- clientes têm de 1 a 2 telefones, e alguns têm 2 veículos;
- as OS vão de janeiro de 2025 a novembro de 2026; apenas as mais recentes (a partir de 15/10/2026) estão abertas ou em andamento;
- cada OS tem de 1 a 3 serviços, um único pagamento e valor pago igual ao total dos serviços;
- cada serviço consome de 1 a 3 produtos (ligação simulada).

Observação: 500 funcionários e 500 fornecedores não são realistas para uma estética de pequeno porte; a quantidade segue a exigência do enunciado.

**Conferência da quantidade de registros**

[Abrir evidências de dados ](prints/dados/)

## CRUD

As operações foram executadas no SQL Editor do Supabase com o script [`sql/03_crud.sql`](sql/03_crud.sql), usando um cliente de teste (CPF 12345678901) e um veículo de teste (placa QWE1R23). Ao final, os dados de teste são removidos.

### Create (INSERT)

**C1 – INSERT do cliente**

[Visualizar C1.PNG ](prints/crud/C1-C6/C1.PNG)

**C2 – INSERT dos telefones**

[Visualizar C2.PNG ](prints/crud/C1-C6/C2.PNG)

**C3 – INSERT do veículo**

[Visualizar C3.PNG ](prints/crud/C1-C6/C3.PNG)

**C4 – INSERT da OS**

[Visualizar C4.PNG ](prints/crud/C1-C6/C4.PNG)

**C5 – INSERT dos serviços da OS**

[Visualizar C5.PNG ](prints/crud/C1-C6/C5.PNG)

**C6 – INSERT do pagamento**

[Visualizar C6.PNG ](prints/crud/C1-C6/C6.PNG)

### Read (SELECT)

**R1 – SELECT simples**

[Visualizar R1.PNG ](prints/crud/R1-R5/R1.PNG)

**R2 – SELECT cliente, telefones e veículos**

[Visualizar R2.PNG ](prints/crud/R1-R5/R2.PNG)

**R3 – SELECT visão completa da OS**

[Visualizar R3.PNG ](prints/crud/R1-R5/R3.PNG)

**R4 – SELECT serviços da OS**

[Visualizar R4.PNG ](prints/crud/R1-R5/R4.PNG)

**R5 – SELECT últimas 10 OS**

[Visualizar R5.PNG ](prints/crud/R1-R5/R5.PNG)

### Update (UPDATE)

**U1 – UPDATE do e-mail**

[Visualizar U1.PNG ](prints/crud/U1-U4/U1.PNG)

**U2 – UPDATE OS em andamento**

[Visualizar U2.PNG ](prints/crud/U1-U4/U2.PNG)

**U3 – UPDATE OS concluída**

[Visualizar U3.PNG ](prints/crud/U1-U4/U3.PNG)

**U4 – UPDATE do estoque**

[Visualizar U4.PNG ](prints/crud/U1-U4/U4.PNG)

### Delete (DELETE)

**D1 – Erro de integridade referencial**

[Visualizar D1%20Erro%20de%20Integridade.PNG ](prints/crud/D1-D6/D1%20Erro%20de%20Integridade.PNG)

**D2 – DELETE do telefone**

[Visualizar D2.PNG ](prints/crud/D1-D6/D2.PNG)

**D3 – DELETE da OS (cascata)**

[Visualizar D3.PNG ](prints/crud/D1-D6/D3.PNG)

**D4 – DELETE do veículo**

[Visualizar D4.PNG ](prints/crud/D1-D6/D4.PNG)

**D5 – DELETE do cliente**

[Visualizar D5.PNG ](prints/crud/D1-D6/D5.PNG)

**D6 – Conferência final**

[Visualizar D6.PNG ](prints/crud/D1-D6/D6.PNG)

## Relatórios

Os prints dos dez resultados estão disponíveis na [pasta de relatórios](prints/relatorios/). As consultas completas também estão no arquivo [`sql/04_relatorios.sql`](sql/04_relatorios.sql).

Foram criadas 10 consultas SQL (arquivo [`sql/04_relatorios.sql`](sql/04_relatorios.sql)), todas com `SELECT`, `WHERE`, `ORDER BY` e `JOIN`, que respondem a perguntas do dia a dia da estética e mostram o relacionamento entre as tabelas.

### Relatório 01 – OS abertas ou em andamento

**Pergunta:** Quais ordens de serviço ainda estão pendentes, de quem são os veículos e quem é o responsável?

**Tabelas envolvidas:** ordem_servico, veiculo, cliente, funcionario, vw_os_valor_total

```sql
select o.id_os, o.status, o.data_abertura,
       c.nome as cliente, v.placa, v.modelo,
       f.nome as funcionario, t.valor_total
from ordem_servico o
join veiculo v     on v.id_veiculo = o.id_veiculo
join cliente c     on c.id_cliente = v.id_cliente
join funcionario f on f.id_funcionario = o.id_funcionario
join vw_os_valor_total t on t.id_os = o.id_os
where o.status in ('aberta', 'em andamento')
order by o.data_abertura, o.id_os;
```

[Visualizar print do Relatório 01](prints/relatorios/Relatorio%201.PNG)

### Relatório 02 – Últimas 20 OS concluídas

**Pergunta:** Quais foram os últimos atendimentos concluídos, com cliente, veículo, funcionário e valor?

**Tabelas envolvidas:** ordem_servico, veiculo, cliente, funcionario, vw_os_valor_total

```sql
select o.id_os, o.data_conclusao,
       c.nome as cliente, v.placa, v.marca, v.modelo,
       f.nome as funcionario, t.valor_total
from ordem_servico o
join veiculo v     on v.id_veiculo = o.id_veiculo
join cliente c     on c.id_cliente = v.id_cliente
join funcionario f on f.id_funcionario = o.id_funcionario
join vw_os_valor_total t on t.id_os = o.id_os
where o.status = 'concluída'
order by o.data_conclusao desc, o.id_os desc
limit 20;
```

[Visualizar print do Relatório 02](prints/relatorios/Relatorio%202.PNG)

### Relatório 03 – Faturamento mensal em 2026

**Pergunta:** Quanto a empresa faturou em cada mês de 2026 com OS concluídas?

**Tabelas envolvidas:** pagamento, ordem_servico

```sql
select to_char(p.data_pagamento, 'YYYY-MM') as mes,
       count(*)          as qtd_pagamentos,
       sum(p.valor_pago) as faturamento
from pagamento p
join ordem_servico o on o.id_os = p.id_os
where o.status = 'concluída'
  and p.data_pagamento >= date '2026-01-01'
  and p.data_pagamento < date '2027-01-01'
group by to_char(p.data_pagamento, 'YYYY-MM')
order by mes;
```

[Visualizar print do Relatório 03](prints/relatorios/Relatorio%203.PNG)

### Relatório 04 – Receita por forma de pagamento

**Pergunta:** Quais formas de pagamento mais geram receita e qual é o ticket médio de cada uma?

**Tabelas envolvidas:** pagamento, ordem_servico

```sql
select p.forma_pagamento,
       count(*)                    as qtd_pagamentos,
       sum(p.valor_pago)           as total_recebido,
       round(avg(p.valor_pago), 2) as ticket_medio
from pagamento p
join ordem_servico o on o.id_os = p.id_os
where o.status = 'concluída'
group by p.forma_pagamento
order by total_recebido desc;
```

[Visualizar print do Relatório 04](prints/relatorios/Relatorio%204.PNG)

### Relatório 05 – 10 serviços mais vendidos

**Pergunta:** Quais serviços são mais executados e quanto cada um rendeu?

**Tabelas envolvidas:** os_servico, servico, ordem_servico

```sql
select s.nome as servico,
       sum(os.quantidade)                      as qtd_vendida,
       sum(os.quantidade * os.preco_cobrado)   as receita
from os_servico os
join servico s       on s.id_servico = os.id_servico
join ordem_servico o on o.id_os = os.id_os
where o.status = 'concluída'
group by s.id_servico, s.nome
order by qtd_vendida desc, receita desc
limit 10;
```

[Visualizar print do Relatório 05](prints/relatorios/Relatorio%205.PNG)

### Relatório 06 – Desempenho dos funcionários

**Pergunta:** Quais funcionários atenderam mais valor em OS concluídas e há quantos anos estão na empresa (atributo derivado tempo de casa)?

**Tabelas envolvidas:** funcionario, ordem_servico, vw_os_valor_total

```sql
select f.nome, f.cargo,
       extract(year from age(current_date, f.data_admissao))::int as anos_de_casa,
       count(*)           as os_concluidas,
       sum(t.valor_total) as valor_atendido
from funcionario f
join ordem_servico o     on o.id_funcionario = f.id_funcionario
join vw_os_valor_total t on t.id_os = o.id_os
where o.status = 'concluída'
group by f.id_funcionario
order by valor_atendido desc
limit 10;
```

[Visualizar print do Relatório 06](prints/relatorios/Relatorio%206.PNG)

### Relatório 07 – Produtos com estoque abaixo do mínimo

**Pergunta:** Quais produtos precisam ser repostos e com qual fornecedor falar?

**Tabelas envolvidas:** produto, fornecedor

```sql
select p.id_produto, p.nome as produto, p.unidade,
       p.quantidade_estoque, p.estoque_minimo,
       (p.estoque_minimo - p.quantidade_estoque) as falta,
       f.razao_social as fornecedor, f.telefone
from produto p
join fornecedor f on f.id_fornecedor = p.id_fornecedor
where p.quantidade_estoque < p.estoque_minimo
order by falta desc, p.nome
limit 20;
```

[Visualizar print do Relatório 07](prints/relatorios/Relatorio%207.PNG)

### Relatório 08 – 10 produtos mais consumidos

**Pergunta:** Quais insumos mais saem do estoque, considerando os serviços das OS concluídas?

**Tabelas envolvidas:** os_servico, ordem_servico, servico_produto, produto

```sql
select p.nome as produto, p.unidade,
       sum(sp.quantidade_usada * os.quantidade) as consumo_total
from os_servico os
join ordem_servico o    on o.id_os = os.id_os
join servico_produto sp on sp.id_servico = os.id_servico
join produto p          on p.id_produto = sp.id_produto
where o.status = 'concluída'
group by p.id_produto, p.nome, p.unidade
order by consumo_total desc
limit 10;
```

[Visualizar print do Relatório 08](prints/relatorios/Relatorio%208.PNG)

### Relatório 09 – 10 clientes que mais gastaram em 2026

**Pergunta:** Quem são os melhores clientes do ano, em valor pago?

**Tabelas envolvidas:** cliente, veiculo, ordem_servico, pagamento

```sql
select c.nome, c.cidade,
       count(o.id_os)    as qtd_os,
       sum(p.valor_pago) as total_gasto
from cliente c
join veiculo v       on v.id_cliente = c.id_cliente
join ordem_servico o on o.id_veiculo = v.id_veiculo
join pagamento p     on p.id_os = o.id_os
where o.data_abertura >= date '2026-01-01'
  and o.data_abertura < date '2027-01-01'
  and o.status = 'concluída'
group by c.id_cliente, c.nome, c.cidade
order by total_gasto desc, c.nome
limit 10;
```

[Visualizar print do Relatório 09](prints/relatorios/Relatorio%209.PNG)

### Relatório 10 – Histórico de serviços de um cliente

**Pergunta:** Que serviços já foram feitos nos veículos de um cliente (aqui, o cliente de ID 8; troque o número para consultar outro)?

**Tabelas envolvidas:** cliente, veiculo, ordem_servico, os_servico, servico

```sql
select c.nome as cliente, v.placa, v.modelo,
       o.id_os, o.data_abertura, o.status,
       s.nome as servico, os.quantidade, os.preco_cobrado
from cliente c
join veiculo v       on v.id_cliente = c.id_cliente
join ordem_servico o on o.id_veiculo = v.id_veiculo
join os_servico os   on os.id_os = o.id_os
join servico s       on s.id_servico = os.id_servico
where c.id_cliente = 8
order by o.data_abertura, o.id_os, s.nome;
```

[Visualizar print do Relatório 10](prints/relatorios/Relatorio%2010.PNG)

---

### Estrutura do repositório

```
estetica-automotiva-bd/
├── README.md
├── sql/
│   ├── 01_schema.sql
│   ├── 02_dados.sql
│   ├── 03_crud.sql
│   └── 04_relatorios.sql
├── imagens/
│   └── der.png
└── prints/
    ├── fisico/
    ├── dados/
    ├── crud/
    └── relatorios/
```

-- =====================================================================
-- 03_crud.sql
-- Demonstração das operações CRUD - Estética Automotiva (Supabase)
-- Rodar DEPOIS do 01_schema.sql e do 02_dados.sql.
-- =====================================================================
-- Como usar para tirar os prints:
--   Rode UM BLOCO POR VEZ (selecione o bloco no SQL Editor e clique em
--   Run). Cada bloco termina com RETURNING ou SELECT, então o resultado
--   aparece na tela e serve de evidência.
-- O cliente de teste é identificado pelo CPF 12345678901 e o veículo
-- pela placa QWE1R23. No final, o bloco DELETE remove tudo, e as tabelas
-- voltam a ter 500 registros.
-- =====================================================================


-- =====================================================================
-- C - CREATE (INSERT)
-- =====================================================================

-- C1. Novo cliente (endereço composto)
insert into cliente (nome, cpf, email, rua, numero, bairro, cidade, uf, cep)
values ('Marcos Antônio Pereira', '12345678901', 'marcos.pereira@exemplo.com.br',
        'Rua das Palmeiras', '120', 'Centro', 'Franca', 'SP', '14400000')
returning *;

-- C2. Telefones do cliente (atributo multivalorado: dois telefones)
insert into telefone_cliente (id_cliente, numero)
select id_cliente, '(16) 99999-1234' from cliente where cpf = '12345678901'
union all
select id_cliente, '(16) 3721-5500'  from cliente where cpf = '12345678901'
returning *;

-- C3. Veículo do cliente (relacionamento 1:N)
insert into veiculo (id_cliente, placa, marca, modelo, ano, cor, tipo)
select id_cliente, 'QWE1R23', 'Toyota', 'Corolla', 2022, 'Prata', 'carro'
from cliente where cpf = '12345678901'
returning *;

-- C4. Ordem de serviço do veículo (data_abertura e status usam o valor padrão)
insert into ordem_servico (id_veiculo, id_funcionario, observacoes)
select id_veiculo, 1, 'OS criada na demonstração do CRUD'
from veiculo where placa = 'QWE1R23'
returning *;

-- C5. Serviços da OS (relacionamento N:N, com quantidade e preço cobrado)
insert into os_servico (id_os, id_servico, quantidade, preco_cobrado)
select o.id_os, s.id_servico, 1, s.preco_base
from ordem_servico o
join veiculo v on v.id_veiculo = o.id_veiculo
cross join servico s
where v.placa = 'QWE1R23'
  and s.id_servico in (1, 21)
returning *;

-- C6. Pagamento da OS (relacionamento 1:1, valor vem da view do valor total)
insert into pagamento (id_os, forma_pagamento, valor_pago)
select o.id_os, 'pix', t.valor_total
from ordem_servico o
join veiculo v on v.id_veiculo = o.id_veiculo
join vw_os_valor_total t on t.id_os = o.id_os
where v.placa = 'QWE1R23'
returning *;


-- =====================================================================
-- R - READ (SELECT)
-- =====================================================================

-- R1. Consulta simples por CPF
select * from cliente where cpf = '12345678901';

-- R2. Cliente com seus telefones e veículos
select c.nome, t.numero as telefone, v.placa, v.marca, v.modelo
from cliente c
join telefone_cliente t on t.id_cliente = c.id_cliente
join veiculo v          on v.id_cliente = c.id_cliente
where c.cpf = '12345678901'
order by t.numero;

-- R3. Visão completa da OS: cliente, veículo, funcionário, valor e pagamento
select o.id_os, c.nome as cliente, v.placa, f.nome as funcionario,
       o.status, t.valor_total, p.forma_pagamento
from ordem_servico o
join veiculo v     on v.id_veiculo = o.id_veiculo
join cliente c     on c.id_cliente = v.id_cliente
join funcionario f on f.id_funcionario = o.id_funcionario
join vw_os_valor_total t on t.id_os = o.id_os
left join pagamento p    on p.id_os = o.id_os
where v.placa = 'QWE1R23';

-- R4. Serviços da OS com o subtotal de cada linha
select o.id_os, s.nome as servico, os.quantidade, os.preco_cobrado,
       (os.quantidade * os.preco_cobrado) as subtotal
from ordem_servico o
join veiculo v     on v.id_veiculo = o.id_veiculo
join os_servico os on os.id_os = o.id_os
join servico s     on s.id_servico = os.id_servico
where v.placa = 'QWE1R23'
order by s.nome;

-- R5. As 10 últimas OS abertas (leitura geral, ordenada)
select id_os, id_veiculo, data_abertura, status
from ordem_servico
order by data_abertura desc, id_os desc
limit 10;


-- =====================================================================
-- U - UPDATE
-- =====================================================================

-- U1. Atualiza o e-mail do cliente
update cliente
set email = 'marcos.antonio@exemplo.com.br'
where cpf = '12345678901'
returning id_cliente, nome, email;

-- U2. A OS entra em andamento
update ordem_servico
set status = 'em andamento'
where id_veiculo = (select id_veiculo from veiculo where placa = 'QWE1R23')
returning id_os, status, data_abertura, data_conclusao;

-- U3. A OS é concluída (data_conclusao >= data_abertura, regra do CHECK)
update ordem_servico
set status = 'concluída',
    data_conclusao = current_date
where id_veiculo = (select id_veiculo from veiculo where placa = 'QWE1R23')
returning id_os, status, data_abertura, data_conclusao;

-- U4. Reposição de estoque: soma 50 unidades ao produto de ID 1
select id_produto, nome, quantidade_estoque from produto where id_produto = 1;

update produto
set quantidade_estoque = quantidade_estoque + 50
where id_produto = 1
returning id_produto, nome, quantidade_estoque;


-- =====================================================================
-- D - DELETE
-- =====================================================================

-- D1. TESTE DE INTEGRIDADE REFERENCIAL (deve dar ERRO)
--     Rode SOMENTE este comando, separado, e tire o print do erro.
--     O cliente tem veículo (ON DELETE RESTRICT), então o banco recusa.
--
-- delete from cliente where cpf = '12345678901';

-- D2. Remove o telefone secundário do cliente
delete from telefone_cliente
where numero = '(16) 3721-5500'
  and id_cliente = (select id_cliente from cliente where cpf = '12345678901')
returning *;

-- D3. Remove a OS de teste
--     ON DELETE CASCADE apaga junto o pagamento e os registros de os_servico.
delete from ordem_servico
where id_veiculo = (select id_veiculo from veiculo where placa = 'QWE1R23')
returning *;

-- D4. Remove o veículo (agora sem OS vinculada)
delete from veiculo
where placa = 'QWE1R23'
returning *;

-- D5. Remove o cliente (o telefone restante cai por CASCADE)
delete from cliente
where cpf = '12345678901'
returning *;

-- D6. Conferência final: nada do cliente de teste deve restar
select 'cliente' as tabela, count(*) as registros from cliente
union all select 'telefone_cliente', count(*) from telefone_cliente
union all select 'veiculo',          count(*) from veiculo
union all select 'ordem_servico',    count(*) from ordem_servico
union all select 'pagamento',        count(*) from pagamento
union all select 'os_servico',       count(*) from os_servico
order by tabela;

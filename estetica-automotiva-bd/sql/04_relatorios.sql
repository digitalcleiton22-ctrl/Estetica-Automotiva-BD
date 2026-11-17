-- =====================================================================
-- 04_relatorios.sql
-- 10 relatórios (consultas) - Estética Automotiva
-- Rodar DEPOIS do 01_schema.sql e do 02_dados.sql.
-- =====================================================================
-- Todas as consultas usam SELECT, WHERE, ORDER BY e JOIN.
-- Rode UMA consulta por vez (selecione o bloco e clique em Run)
-- e tire um print de cada resultado.
-- =====================================================================

-- ---------------------------------------------------------------------
-- RELATÓRIO 01 - OS abertas ou em andamento
-- Pergunta: Quais ordens de serviço ainda estão pendentes, de quem são os veículos e quem é o responsável?
-- Tabelas: ordem_servico, veiculo, cliente, funcionario, vw_os_valor_total
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- RELATÓRIO 02 - Últimas 20 OS concluídas
-- Pergunta: Quais foram os últimos atendimentos concluídos, com cliente, veículo, funcionário e valor?
-- Tabelas: ordem_servico, veiculo, cliente, funcionario, vw_os_valor_total
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- RELATÓRIO 03 - Faturamento mensal em 2026
-- Pergunta: Quanto a empresa faturou em cada mês de 2026 com OS concluídas?
-- Tabelas: pagamento, ordem_servico
-- ---------------------------------------------------------------------
select to_char(p.data_pagamento, 'YYYY-MM') as mes,
       count(*)          as qtd_pagamentos,
       sum(p.valor_pago) as faturamento
from pagamento p
join ordem_servico o on o.id_os = p.id_os
where o.status = 'concluída'
  and p.data_pagamento >= date '2026-01-01'
group by to_char(p.data_pagamento, 'YYYY-MM')
order by mes;

-- ---------------------------------------------------------------------
-- RELATÓRIO 04 - Receita por forma de pagamento
-- Pergunta: Quais formas de pagamento mais geram receita e qual é o ticket médio de cada uma?
-- Tabelas: pagamento, ordem_servico
-- ---------------------------------------------------------------------
select p.forma_pagamento,
       count(*)                    as qtd_pagamentos,
       sum(p.valor_pago)           as total_recebido,
       round(avg(p.valor_pago), 2) as ticket_medio
from pagamento p
join ordem_servico o on o.id_os = p.id_os
where o.status = 'concluída'
group by p.forma_pagamento
order by total_recebido desc;

-- ---------------------------------------------------------------------
-- RELATÓRIO 05 - 10 serviços mais vendidos
-- Pergunta: Quais serviços são mais executados e quanto cada um rendeu?
-- Tabelas: os_servico, servico, ordem_servico
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- RELATÓRIO 06 - Desempenho dos funcionários
-- Pergunta: Quais funcionários atenderam mais valor em OS concluídas e há quantos anos estão na empresa (atributo derivado tempo de casa)?
-- Tabelas: funcionario, ordem_servico, vw_os_valor_total
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- RELATÓRIO 07 - Produtos com estoque abaixo do mínimo
-- Pergunta: Quais produtos precisam ser repostos e com qual fornecedor falar?
-- Tabelas: produto, fornecedor
-- ---------------------------------------------------------------------
select p.id_produto, p.nome as produto, p.unidade,
       p.quantidade_estoque, p.estoque_minimo,
       (p.estoque_minimo - p.quantidade_estoque) as falta,
       f.razao_social as fornecedor, f.telefone
from produto p
join fornecedor f on f.id_fornecedor = p.id_fornecedor
where p.quantidade_estoque < p.estoque_minimo
order by falta desc, p.nome
limit 20;

-- ---------------------------------------------------------------------
-- RELATÓRIO 08 - 10 produtos mais consumidos
-- Pergunta: Quais insumos mais saem do estoque, considerando os serviços das OS concluídas?
-- Tabelas: os_servico, ordem_servico, servico_produto, produto
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- RELATÓRIO 09 - 10 clientes que mais gastaram em 2026
-- Pergunta: Quem são os melhores clientes do ano, em valor pago?
-- Tabelas: cliente, veiculo, ordem_servico, pagamento
-- ---------------------------------------------------------------------
select c.nome, c.cidade,
       count(o.id_os)    as qtd_os,
       sum(p.valor_pago) as total_gasto
from cliente c
join veiculo v       on v.id_cliente = c.id_cliente
join ordem_servico o on o.id_veiculo = v.id_veiculo
join pagamento p     on p.id_os = o.id_os
where o.data_abertura >= date '2026-01-01'
group by c.id_cliente, c.nome, c.cidade
order by total_gasto desc, c.nome
limit 10;

-- ---------------------------------------------------------------------
-- RELATÓRIO 10 - Histórico de serviços de um cliente
-- Pergunta: Que serviços já foram feitos nos veículos de um cliente (aqui, o cliente de ID 8; troque o número para consultar outro)?
-- Tabelas: cliente, veiculo, ordem_servico, os_servico, servico
-- ---------------------------------------------------------------------
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

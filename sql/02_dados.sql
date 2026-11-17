-- =====================================================================
-- 02_dados.sql
-- Carga de dados - Sistema de Gestão de Estética Automotiva
-- Rodar DEPOIS do 01_schema.sql.
-- =====================================================================
-- Todos os dados são fictícios e gerados por SQL (generate_series).
-- Os valores são calculados a partir do índice (i), então o script é
-- determinístico: rodar de novo gera exatamente os mesmos dados.
-- Cada INSERT usa ORDER BY para que os IDs automáticos saiam em
-- sequência (1, 2, 3...) e as chaves estrangeiras apontem para linhas
-- que realmente existem.
-- =====================================================================

-- Limpa tudo e reinicia os IDs em 1 (permite rodar o script várias vezes)
truncate table
    servico_produto, os_servico, pagamento, ordem_servico,
    servico, produto, fornecedor, funcionario,
    veiculo, telefone_cliente, cliente
restart identity cascade;

-- ---------------------------------------------------------------------
-- 1. CLIENTE (500 registros)
--    30 nomes x 20 sobrenomes = 600 combinações; (i*97) % 600 embaralha
--    e garante que nenhum nome completo se repita.
-- ---------------------------------------------------------------------
insert into cliente (nome, cpf, email, data_cadastro, rua, numero, bairro, cidade, uf, cep)
select
    a.pn[1 + (g.j % cardinality(a.pn))] || ' ' ||
        a.sn[1 + ((g.j / cardinality(a.pn)) % cardinality(a.sn))],
    lpad((30000000000::bigint + g.i::bigint * 1234567)::text, 11, '0'),
    'cliente' || g.i || '@exemplo.com.br',
    date '2024-01-01' + (g.i * 5) % 660,
    a.ru[1 + g.i % cardinality(a.ru)],
    ((g.i * 17) % 1900 + 10)::text,
    a.ba[1 + (g.i * 3) % cardinality(a.ba)],
    a.ci[1 + (g.i * 7) % cardinality(a.ci)],
    'SP',
    lpad((14000000 + g.i * 13)::text, 8, '0')
from (select i, (i * 97) % 600 as j from generate_series(1, 500) as t(i)) g
cross join (
    select
        array['João','Maria','José','Ana','Pedro','Juliana','Lucas','Fernanda','Carlos','Camila',
              'Rafael','Patrícia','Marcos','Aline','Bruno','Larissa','Felipe','Beatriz','Gustavo','Letícia',
              'Rodrigo','Amanda','Thiago','Bruna','Diego','Carolina','Leandro','Renata','Eduardo','Vanessa'] as pn,
        array['Silva','Santos','Oliveira','Souza','Rodrigues','Ferreira','Alves','Pereira','Lima','Gomes',
              'Costa','Ribeiro','Martins','Carvalho','Almeida','Lopes','Soares','Fernandes','Vieira','Barbosa'] as sn,
        array['Rua das Palmeiras','Avenida Brasil','Rua XV de Novembro','Rua Sete de Setembro',
              'Avenida Dr. Armando','Rua Goiás','Rua Minas Gerais','Avenida Rio Branco',
              'Rua Tiradentes','Rua Santos Dumont','Rua das Acácias','Avenida Presidente Vargas'] as ru,
        array['Centro','Jardim América','Vila Nova','Jardim Paulista','Bela Vista',
              'Vila Industrial','Jardim Europa','São Sebastião','Parque Industrial','Jardim Primavera'] as ba,
        array['Franca','Ribeirão Preto','Orlândia','Batatais','Ituverava','Guará','Igarapava','Altinópolis'] as ci
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 2. TELEFONE_CLIENTE (500 registros)
--    Atributo multivalorado: clientes 1 a 400 têm 1 telefone e
--    clientes 1 a 100 têm um segundo telefone.
-- ---------------------------------------------------------------------
insert into telefone_cliente (id_cliente, numero)
select
    case when g.i <= 400 then g.i else g.i - 400 end,
    '(' || (array['16','17','19','11'])[1 + g.i % 4] || ') 9' ||
        lpad(((g.i * 173) % 10000)::text, 4, '0') || '-' ||
        lpad(((g.i * 89) % 10000)::text, 4, '0')
from generate_series(1, 500) as g(i)
order by g.i;

-- ---------------------------------------------------------------------
-- 3. VEICULO (500 registros)
--    Clientes 1 a 450 têm 1 veículo; clientes 1 a 50 têm também um 2º.
--    Placa no padrão Mercosul (LLLNLNN), única por construção.
-- ---------------------------------------------------------------------
insert into veiculo (id_cliente, placa, marca, modelo, ano, cor, tipo)
select
    case when g.i <= 450 then g.i else g.i - 450 end,
    chr(65 + g.i % 26) || chr(65 + (g.i / 26) % 26) || chr(65 + (g.i / 676) % 26) ||
        (g.i % 10)::text || chr(65 + (g.i * 7) % 26) ||
        ((g.i * 3) % 10)::text || ((g.i * 11) % 10)::text,
    split_part(a.mv[1 + (g.i * 7) % cardinality(a.mv)], '|', 1),
    split_part(a.mv[1 + (g.i * 7) % cardinality(a.mv)], '|', 2),
    2008 + (g.i * 5) % 18,
    a.co[1 + (g.i * 3) % cardinality(a.co)],
    split_part(a.mv[1 + (g.i * 7) % cardinality(a.mv)], '|', 3)
from generate_series(1, 500) as g(i)
cross join (
    select
        array['Volkswagen|Gol|carro','Volkswagen|Polo|carro','Volkswagen|T-Cross|carro',
              'Fiat|Uno|carro','Fiat|Argo|carro','Fiat|Mobi|carro','Fiat|Strada|carro',
              'Chevrolet|Onix|carro','Chevrolet|Tracker|carro','Chevrolet|S10|carro',
              'Hyundai|HB20|carro','Hyundai|Creta|carro','Toyota|Corolla|carro','Toyota|Hilux|carro',
              'Honda|Civic|carro','Honda|HR-V|carro','Renault|Kwid|carro','Renault|Duster|carro',
              'Jeep|Renegade|carro','Jeep|Compass|carro','Ford|Ka|carro','Ford|Ranger|carro',
              'Nissan|Kicks|carro','Honda|CG 160|moto','Honda|Biz 125|moto','Yamaha|Fazer 250|moto',
              'Yamaha|MT-03|moto','Honda|CB 500F|moto'] as mv,
        array['Branco','Preto','Prata','Cinza','Vermelho','Azul','Verde','Bege'] as co
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 4. FUNCIONARIO (500 registros)
--    (o enunciado exige 500 por tabela; em uma estética real seriam bem menos)
-- ---------------------------------------------------------------------
insert into funcionario (nome, cpf, cargo, data_admissao, salario)
select
    a.pn[1 + (g.j % cardinality(a.pn))] || ' ' ||
        a.sn[1 + ((g.j / cardinality(a.pn)) % cardinality(a.sn))],
    lpad((40000000000::bigint + g.i::bigint * 2345679)::text, 11, '0'),
    a.ca[1 + g.i % cardinality(a.ca)],
    date '2012-01-01' + (g.i * 17) % 4900,
    (1800 + (g.i * 137) % 3200 + (g.i % 100) / 100.0)::numeric(10,2)
from (select i, (i * 101) % 600 as j from generate_series(1, 500) as t(i)) g
cross join (
    select
        array['João','Maria','José','Ana','Pedro','Juliana','Lucas','Fernanda','Carlos','Camila',
              'Rafael','Patrícia','Marcos','Aline','Bruno','Larissa','Felipe','Beatriz','Gustavo','Letícia',
              'Rodrigo','Amanda','Thiago','Bruna','Diego','Carolina','Leandro','Renata','Eduardo','Vanessa'] as pn,
        array['Silva','Santos','Oliveira','Souza','Rodrigues','Ferreira','Alves','Pereira','Lima','Gomes',
              'Costa','Ribeiro','Martins','Carvalho','Almeida','Lopes','Soares','Fernandes','Vieira','Barbosa'] as sn,
        array['Lavador','Polidor','Detalhista','Atendente','Gerente',
              'Auxiliar de Estética','Instalador de Película','Estoquista'] as ca
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 5. FORNECEDOR (500 registros)
-- ---------------------------------------------------------------------
insert into fornecedor (razao_social, cnpj, email, telefone)
select
    a.pf[1 + g.i % cardinality(a.pf)] || ' ' ||
        a.sf[1 + (g.i / cardinality(a.pf)) % cardinality(a.sf)] || ' ' ||
        lpad(g.i::text, 3, '0') || ' Ltda',
    lpad((10000000000000::bigint + g.i::bigint * 987654321)::text, 14, '0'),
    'contato' || g.i || '@fornecedor.com.br',
    '(16) 3' || lpad(((g.i * 271) % 1000)::text, 3, '0') || '-' ||
        lpad(((g.i * 643) % 10000)::text, 4, '0')
from generate_series(1, 500) as g(i)
cross join (
    select
        array['Brilho','Auto','Master','Prime','Speed','Nova','Super','Top','Max','Pro'] as pf,
        array['Distribuidora','Comércio','Importadora','Química','Automotiva','Representações'] as sf
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 6. PRODUTO (500 registros)
--    Fornecedores 1 a 400 recebem produtos; alguns fornecem 2 produtos.
-- ---------------------------------------------------------------------
insert into produto (id_fornecedor, nome, marca, unidade, preco_custo, quantidade_estoque, estoque_minimo)
select
    1 + (g.i * 7) % 400,
    split_part(a.pr[1 + g.i % cardinality(a.pr)], '|', 1) || ' ' ||
        a.ma[1 + (g.i / cardinality(a.pr)) % cardinality(a.ma)] || ' ' ||
        a.li[1 + (g.i / cardinality(a.pr) / cardinality(a.ma)) % cardinality(a.li)],
    a.ma[1 + (g.i / cardinality(a.pr)) % cardinality(a.ma)],
    split_part(a.pr[1 + g.i % cardinality(a.pr)], '|', 2),
    (8 + ((g.i * 53) % 20000) / 100.0)::numeric(10,2),
    (g.i * 17) % 200,
    5 + g.i % 20
from generate_series(1, 500) as g(i)
cross join (
    select
        array['Shampoo Automotivo|L','Cera de Carnaúba|kg','Vitrificador Cerâmico|ml','Polidor Composto|L',
              'Microfibra Premium|un','Limpa Vidros|L','Pretinho para Pneus|L','Descontaminante de Pintura|L',
              'Hidratante de Couro|ml','Limpador de Estofados|L','Selante Sintético|ml','Massa de Polir|kg',
              'Boina de Espuma|un','Desengraxante|L','Removedor de Piche|ml','Aromatizante Automotivo|un',
              'Argila de Descontaminação|un','Revitalizador de Plásticos|L','Lustrador de Pintura|L',
              'Limpador de Rodas|L'] as pr,
        array['BrilhoMax','AutoShine','CleanCar','PrimeCar','Nano Brasil',
              'CeraPro','TopGloss','Lustro','ProDetail','EcoWash'] as ma,
        array['Standard','Profissional','Premium'] as li
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 7. SERVICO (500 registros)
--    20 serviços x 5 portes de veículo x 5 pacotes = 500 combinações únicas.
--    Preço e duração variam conforme o porte e o pacote.
-- ---------------------------------------------------------------------
insert into servico (nome, descricao, preco_base, duracao_estimada_min)
select
    a.sv[1 + g.s] || ' - ' || a.po[1 + g.p] || ' (' || a.ni[1 + g.n] || ')',
    'Serviço de ' || lower(a.sv[1 + g.s]) || ' para veículo do tipo ' ||
        lower(a.po[1 + g.p]) || ', pacote ' || lower(a.ni[1 + g.n]) || '.',
    round(a.bp[1 + g.s] * a.fp[1 + g.p] * a.fn[1 + g.n], 2),
    round(a.bd[1 + g.s] * a.fd[1 + g.p] * a.fn[1 + g.n])::int
from (
    select i,
           (i - 1) % 20         as s,
           ((i - 1) / 20) % 5   as p,
           ((i - 1) / 100) % 5  as n
    from generate_series(1, 500) as t(i)
) g
cross join (
    select
        array['Lavagem Simples','Lavagem Completa','Polimento Técnico','Polimento Comercial',
              'Vitrificação de Pintura','Higienização Interna','Hidratação de Couro',
              'Cristalização de Vidros','Revitalização de Faróis','Descontaminação de Pintura',
              'Enceramento','Lavagem de Motor','Limpeza de Rodas e Caixas de Roda',
              'Impermeabilização de Estofados','Remoção de Chuva Ácida',
              'Aplicação de Película de Proteção','Higienização de Ar-Condicionado',
              'Lavagem a Seco','Revitalização de Plásticos','Aplicação de Coating Cerâmico'] as sv,
        array[50, 90, 350, 200, 900, 180, 150, 120, 100, 130,
              80, 70, 60, 220, 160, 1500, 140, 110, 90, 1200] as bp,
        array[40, 90, 300, 180, 360, 120, 90, 60, 45, 70,
              40, 30, 30, 120, 100, 480, 60, 50, 40, 420] as bd,
        array['Hatch','Sedan','SUV','Picape','Moto'] as po,
        array[1.00, 1.15, 1.35, 1.40, 0.70] as fp,
        array[1.00, 1.10, 1.30, 1.30, 0.70] as fd,
        array['Básico','Padrão','Premium','Premium Plus','Express'] as ni,
        array[0.80, 1.00, 1.30, 1.60, 0.90] as fn
) a
order by g.i;

-- ---------------------------------------------------------------------
-- 8. ORDEM_SERVICO (500 registros)
--    Datas entre 01/01/2025 e 01/11/2026. OS abertas há muito tempo estão
--    concluídas; só as mais recentes (a partir de 15/10/2026) ficam
--    'aberta' ou 'em andamento'.
-- ---------------------------------------------------------------------
insert into ordem_servico (id_veiculo, id_funcionario, data_abertura, data_conclusao, status, observacoes)
select
    1 + (g.i * 7) % 450,
    1 + (g.i * 13) % 300,
    g.dt,
    case when g.dt < date '2026-10-15' then g.dt + g.i % 3 end,
    case when g.dt < date '2026-10-15' then 'concluída'
         when g.i % 2 = 0               then 'aberta'
         else 'em andamento' end,
    case when g.i % 7 = 0 then
        (array['Cliente pediu atenção especial na pintura',
               'Veículo chegou com sujeira pesada',
               'Agendado com antecedência',
               'Cliente aguarda no local',
               'Retirar até o fim do dia'])[1 + g.i % 5]
    end
from (
    select i, date '2025-01-01' + (i * 7) % 670 as dt
    from generate_series(1, 500) as t(i)
) g
order by g.i;

-- ---------------------------------------------------------------------
-- 9. OS_SERVICO (N:N entre ordem_servico e servico)
--    Cada OS tem de 1 a 3 serviços (~1000 linhas, acima do mínimo de 500).
--    O preço cobrado pode ter desconto de 0% a 15% sobre o preço base.
-- ---------------------------------------------------------------------
insert into os_servico (id_os, id_servico, quantidade, preco_cobrado)
select
    o.i,
    s.id_servico,
    case when (o.i + kk.n) % 10 = 0 then 2 else 1 end,
    round(s.preco_base * (1 - (o.i % 4) * 0.05), 2)
from generate_series(1, 500) as o(i)
cross join generate_series(1, 3) as kk(n)
join servico s on s.id_servico = 1 + (o.i * 17 + kk.n * 131) % 500
where kk.n <= 1 + o.i % 3
order by o.i, kk.n;

-- ---------------------------------------------------------------------
-- 10. PAGAMENTO (500 registros, 1:1 com ordem_servico)
--     Pagamento feito no balcão, no valor total da OS (calculado pela view).
-- ---------------------------------------------------------------------
insert into pagamento (id_os, forma_pagamento, valor_pago, data_pagamento)
select
    os.id_os,
    (array['pix','cartão débito','cartão crédito','dinheiro'])[1 + os.id_os % 4],
    v.valor_total,
    coalesce(os.data_conclusao, os.data_abertura)
from ordem_servico os
join vw_os_valor_total v on v.id_os = os.id_os
order by os.id_os;

-- ---------------------------------------------------------------------
-- 11. SERVICO_PRODUTO (N:N entre servico e produto)
--     Cada serviço consome de 1 a 3 produtos (~1000 linhas).
-- ---------------------------------------------------------------------
insert into servico_produto (id_servico, id_produto, quantidade_usada)
select
    s.i,
    1 + (s.i * 29 + kk.n * 151) % 500,
    round(0.5 + ((s.i * kk.n * 7) % 100) / 10.0, 2)
from generate_series(1, 500) as s(i)
cross join generate_series(1, 3) as kk(n)
where kk.n <= 1 + s.i % 3
order by s.i, kk.n;

-- ---------------------------------------------------------------------
-- 12. CONFERÊNCIA: quantidade de registros por tabela
--     (tire um print deste resultado para o README)
-- ---------------------------------------------------------------------
select 'cliente'          as tabela, count(*) as registros from cliente
union all select 'telefone_cliente', count(*) from telefone_cliente
union all select 'veiculo',          count(*) from veiculo
union all select 'funcionario',      count(*) from funcionario
union all select 'fornecedor',       count(*) from fornecedor
union all select 'produto',          count(*) from produto
union all select 'servico',          count(*) from servico
union all select 'ordem_servico',    count(*) from ordem_servico
union all select 'pagamento',        count(*) from pagamento
union all select 'os_servico',       count(*) from os_servico
union all select 'servico_produto',  count(*) from servico_produto
order by tabela;

-- =====================================================================
-- 01_schema.sql
-- Modelagem Física - Sistema de Gestão de Estética Automotiva
-- SGBD: PostgreSQL (Supabase)
-- =====================================================================
-- Ordem de criação respeita as chaves estrangeiras (tabelas pai primeiro).
-- O bloco DROP permite rodar o script várias vezes durante os testes.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Limpeza (apaga as tabelas na ordem inversa das dependências)
-- ---------------------------------------------------------------------
drop view  if exists vw_os_valor_total;
drop table if exists servico_produto  cascade;
drop table if exists os_servico       cascade;
drop table if exists pagamento        cascade;
drop table if exists ordem_servico    cascade;
drop table if exists servico          cascade;
drop table if exists produto          cascade;
drop table if exists fornecedor       cascade;
drop table if exists funcionario      cascade;
drop table if exists veiculo          cascade;
drop table if exists telefone_cliente cascade;
drop table if exists cliente          cascade;

-- ---------------------------------------------------------------------
-- 1. CLIENTE
--    Atributo composto: endereço (rua, numero, bairro, cidade, uf, cep)
-- ---------------------------------------------------------------------
create table cliente (
    id_cliente     integer generated always as identity primary key,
    nome           varchar(100) not null,
    cpf            char(11)     not null unique,
    email          varchar(100),
    data_cadastro  date         not null default current_date,
    -- endereço (atributo composto)
    rua            varchar(100),
    numero         varchar(10),
    bairro         varchar(60),
    cidade         varchar(60),
    uf             char(2),
    cep            char(8),
    constraint ck_cliente_cpf check (cpf ~ '^[0-9]{11}$'),
    constraint ck_cliente_uf  check (uf is null or uf ~ '^[A-Z]{2}$')
);

-- ---------------------------------------------------------------------
-- 2. TELEFONE_CLIENTE
--    Atributo multivalorado: um cliente pode ter vários telefones
--    Relacionamento 1:N com cliente
-- ---------------------------------------------------------------------
create table telefone_cliente (
    id_telefone  integer generated always as identity primary key,
    id_cliente   integer     not null,
    numero       varchar(15) not null,
    constraint fk_telefone_cliente
        foreign key (id_cliente) references cliente (id_cliente)
        on delete cascade
);

-- ---------------------------------------------------------------------
-- 3. VEICULO
--    Relacionamento 1:N: um cliente possui vários veículos
-- ---------------------------------------------------------------------
create table veiculo (
    id_veiculo  integer generated always as identity primary key,
    id_cliente  integer     not null,
    placa       varchar(8)  not null unique,
    marca       varchar(40) not null,
    modelo      varchar(60) not null,
    ano         integer,
    cor         varchar(30),
    tipo        varchar(10) not null default 'carro',
    constraint fk_veiculo_cliente
        foreign key (id_cliente) references cliente (id_cliente)
        on delete restrict,
    constraint ck_veiculo_tipo check (tipo in ('carro', 'moto')),
    constraint ck_veiculo_ano  check (ano is null or ano between 1950 and 2100)
);

-- ---------------------------------------------------------------------
-- 4. FUNCIONARIO
--    Atributo derivado (tempo de casa) é calculado a partir de data_admissao
-- ---------------------------------------------------------------------
create table funcionario (
    id_funcionario  integer generated always as identity primary key,
    nome            varchar(100)  not null,
    cpf             char(11)      not null unique,
    cargo           varchar(50)   not null,
    data_admissao   date          not null,
    salario         numeric(10,2) not null,
    constraint ck_funcionario_cpf     check (cpf ~ '^[0-9]{11}$'),
    constraint ck_funcionario_salario check (salario > 0)
);

-- ---------------------------------------------------------------------
-- 5. FORNECEDOR
-- ---------------------------------------------------------------------
create table fornecedor (
    id_fornecedor  integer generated always as identity primary key,
    razao_social   varchar(120) not null,
    cnpj           char(14)     not null unique,
    email          varchar(100),
    telefone       varchar(15),
    constraint ck_fornecedor_cnpj check (cnpj ~ '^[0-9]{14}$')
);

-- ---------------------------------------------------------------------
-- 6. PRODUTO
--    Relacionamento 1:N: um fornecedor fornece vários produtos
-- ---------------------------------------------------------------------
create table produto (
    id_produto          integer generated always as identity primary key,
    id_fornecedor       integer       not null,
    nome                varchar(100)  not null,
    marca               varchar(50),
    unidade             varchar(10)   not null default 'un',
    preco_custo         numeric(10,2) not null,
    quantidade_estoque  integer       not null default 0,
    estoque_minimo      integer       not null default 0,
    constraint fk_produto_fornecedor
        foreign key (id_fornecedor) references fornecedor (id_fornecedor)
        on delete restrict,
    constraint ck_produto_preco   check (preco_custo >= 0),
    constraint ck_produto_estoque check (quantidade_estoque >= 0 and estoque_minimo >= 0)
);

-- ---------------------------------------------------------------------
-- 7. SERVICO
-- ---------------------------------------------------------------------
create table servico (
    id_servico            integer generated always as identity primary key,
    nome                  varchar(100)  not null,
    descricao             text,
    preco_base            numeric(10,2) not null,
    duracao_estimada_min  integer       not null,
    constraint ck_servico_preco   check (preco_base >= 0),
    constraint ck_servico_duracao check (duracao_estimada_min > 0)
);

-- ---------------------------------------------------------------------
-- 8. ORDEM_SERVICO
--    Relacionamentos 1:N com veiculo e com funcionario
--    O cliente é obtido pelo veículo (evita inconsistência de dono)
-- ---------------------------------------------------------------------
create table ordem_servico (
    id_os           integer generated always as identity primary key,
    id_veiculo      integer     not null,
    id_funcionario  integer     not null,
    data_abertura   date        not null default current_date,
    data_conclusao  date,
    status          varchar(20) not null default 'aberta',
    observacoes     text,
    constraint fk_os_veiculo
        foreign key (id_veiculo) references veiculo (id_veiculo)
        on delete restrict,
    constraint fk_os_funcionario
        foreign key (id_funcionario) references funcionario (id_funcionario)
        on delete restrict,
    constraint ck_os_status
        check (status in ('aberta', 'em andamento', 'concluída', 'cancelada')),
    constraint ck_os_datas
        check (data_conclusao is null or data_conclusao >= data_abertura)
);

-- ---------------------------------------------------------------------
-- 9. PAGAMENTO
--    Relacionamento 1:1 com ordem_servico (UNIQUE na chave estrangeira)
-- ---------------------------------------------------------------------
create table pagamento (
    id_pagamento     integer generated always as identity primary key,
    id_os            integer       not null unique,
    forma_pagamento  varchar(20)   not null,
    valor_pago       numeric(10,2) not null,
    data_pagamento   date          not null default current_date,
    constraint fk_pagamento_os
        foreign key (id_os) references ordem_servico (id_os)
        on delete cascade,
    constraint ck_pagamento_forma
        check (forma_pagamento in ('dinheiro', 'pix', 'cartão débito', 'cartão crédito')),
    constraint ck_pagamento_valor check (valor_pago > 0)
);

-- ---------------------------------------------------------------------
-- 10. OS_SERVICO
--     Relacionamento N:N entre ordem_servico e servico
-- ---------------------------------------------------------------------
create table os_servico (
    id_os          integer       not null,
    id_servico     integer       not null,
    quantidade     integer       not null default 1,
    preco_cobrado  numeric(10,2) not null,
    primary key (id_os, id_servico),
    constraint fk_os_servico_os
        foreign key (id_os) references ordem_servico (id_os)
        on delete cascade,
    constraint fk_os_servico_servico
        foreign key (id_servico) references servico (id_servico)
        on delete restrict,
    constraint ck_os_servico_qtd   check (quantidade > 0),
    constraint ck_os_servico_preco check (preco_cobrado >= 0)
);

-- ---------------------------------------------------------------------
-- 11. SERVICO_PRODUTO
--     Relacionamento N:N entre servico e produto (insumos usados)
-- ---------------------------------------------------------------------
create table servico_produto (
    id_servico        integer       not null,
    id_produto        integer       not null,
    quantidade_usada  numeric(10,2) not null,
    primary key (id_servico, id_produto),
    constraint fk_servico_produto_servico
        foreign key (id_servico) references servico (id_servico)
        on delete cascade,
    constraint fk_servico_produto_produto
        foreign key (id_produto) references produto (id_produto)
        on delete restrict,
    constraint ck_servico_produto_qtd check (quantidade_usada > 0)
);

-- ---------------------------------------------------------------------
-- 12. ÍNDICES nas chaves estrangeiras
--     (o Postgres não cria índice automático em FK; isso acelera JOINs)
--     As PKs compostas já cobrem id_os e id_servico como primeira coluna.
-- ---------------------------------------------------------------------
create index idx_telefone_cliente_id_cliente on telefone_cliente (id_cliente);
create index idx_veiculo_id_cliente          on veiculo (id_cliente);
create index idx_produto_id_fornecedor       on produto (id_fornecedor);
create index idx_os_id_veiculo               on ordem_servico (id_veiculo);
create index idx_os_id_funcionario           on ordem_servico (id_funcionario);
create index idx_os_servico_id_servico       on os_servico (id_servico);
create index idx_servico_produto_id_produto  on servico_produto (id_produto);

-- ---------------------------------------------------------------------
-- 13. VIEW: atributo derivado valor_total da OS
--     valor_total = soma de (quantidade * preco_cobrado) dos serviços da OS
-- ---------------------------------------------------------------------
create view vw_os_valor_total
with (security_invoker = true) as
select
    os.id_os,
    coalesce(sum(s.quantidade * s.preco_cobrado), 0)::numeric(10,2) as valor_total
from ordem_servico os
left join os_servico s on s.id_os = os.id_os
group by os.id_os;

-- ---------------------------------------------------------------------
-- 14. Segurança: habilita RLS em todas as tabelas
--     Sem políticas, a API pública (anon) fica bloqueada. O Table Editor
--     e o SQL Editor do painel continuam funcionando normalmente.
-- ---------------------------------------------------------------------
alter table cliente          enable row level security;
alter table telefone_cliente enable row level security;
alter table veiculo          enable row level security;
alter table funcionario      enable row level security;
alter table fornecedor       enable row level security;
alter table produto          enable row level security;
alter table servico          enable row level security;
alter table ordem_servico    enable row level security;
alter table pagamento        enable row level security;
alter table os_servico       enable row level security;
alter table servico_produto  enable row level security;

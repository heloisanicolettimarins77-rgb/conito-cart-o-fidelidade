# Conito — Cartão fidelidade

Site estático (HTML + JS) com banco no Supabase. Pronto para a Vercel, sem build.

## Como funciona

- **Cliente**: abre o site, digita o telefone e vê o cartão (só nome, 4 últimos dígitos e selos).
- **Atendente/admin**: "Área do administrador" → e-mail e senha → procura a cliente por nome ou telefone →
  `+1 doce comprado` → botão **Abrir WhatsApp** já com a mensagem pronta para o número dela.
- Ao completar o cartão (padrão: 10), aparece "Entreguei o conito grátis", que zera o cartão.

## Configurar o Supabase (uma vez)

1. **SQL Editor → New query**: cole o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**.
2. **Authentication → Users → Add user → Create new user**: e-mail `vivi@conito.com.br` (ou outro) e uma senha.
   Marque "Auto Confirm User".
   - Para liberar outro e-mail como admin, adicione-o na tabela `admins`.
3. **Authentication → Sign In / Providers**: desligue **"Allow new users to sign up"** (ninguém precisa se cadastrar sozinho).

## Vercel

Import do repositório → Framework Preset: **Other** → sem build command, output = raiz. Deploy.
Depois, em *Ajustes* dentro do site, o link da mensagem do WhatsApp já usa o endereço do site automaticamente.

## Segurança

- `config.js` tem só a chave **publishable** (feita para ficar no navegador).
- A chave **secreta** (`sb_secret_...`) nunca deve entrar neste repositório.
- Telefones completos só são lidos por quem está na tabela `admins` (RLS).

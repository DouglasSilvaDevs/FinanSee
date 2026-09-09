# FinanSee

<p align="center">
  <strong>Gerenciador de finanças pessoais desenvolvido com Flutter.</strong>
</p>

<p align="center">
  Controle receitas, despesas, contas, orçamentos e metas em um só lugar.
</p>

---

## 📱 Sobre

O **FinanSee** é um aplicativo de gerenciamento financeiro pessoal desenvolvido com foco em simplicidade, organização e uma experiência moderna.

O projeto foi criado como parte do meu portfólio e utiliza persistência local, gerenciamento de estado, notificações, relatórios e backup de dados.

---

## ✨ Funcionalidades

- 💰 Dashboard com resumo financeiro
- 💳 Gerenciamento de contas
- 💸 Receitas e despesas
- 🏷️ Categorias personalizadas
- 📊 Orçamentos mensais
- 🔁 Transações recorrentes
- 🎯 Metas financeiras e aportes
- 📈 Relatórios e gráficos
- 📄 Exportação em PDF e CSV
- 🔔 Notificações e lembretes
- 💾 Backup e restauração
- 🌗 Tema claro, escuro e automático
- 👋 Onboarding

---

## 🖼️ Screenshots

<p align="center">
  <img src="screenshots/dashboard.png" width="240" />
  <img src="screenshots/transactions.png" width="240" />
  <img src="screenshots/reports.png" width="240" />
</p>

<p align="center">
  <img src="screenshots/budgets.png" width="240" />
  <img src="screenshots/goals.png" width="240" />
  <img src="screenshots/dark_mode.png" width="240" />
</p>

---

## 🛠️ Tecnologias

- Flutter
- Dart
- Riverpod
- Drift
- SQLite
- GoRouter
- Material 3
- fl_chart
- SharedPreferences
- flutter_local_notifications

---

## 🏗️ Estrutura

O projeto é organizado por funcionalidades, separando interface, regras de negócio e acesso aos dados.

```text
lib/
├── core/
│   ├── database/
│   ├── router/
│   ├── theme/
│   └── widgets/
│
├── features/
│   ├── dashboard/
│   ├── transactions/
│   ├── accounts/
│   ├── categories/
│   ├── budgets/
│   ├── recurring/
│   ├── goals/
│   ├── reports/
│   ├── notifications/
│   └── settings/
│
├── app.dart
└── main.dart
```

---

## 🚀 Como executar

Clone o repositório:

```bash
git clone URL_DO_SEU_REPOSITORIO
```

Entre na pasta:

```bash
cd finansee
```

Instale as dependências:

```bash
fvm flutter pub get
```

Execute:

```bash
fvm flutter run
```

---

## 📦 APK

Para gerar o APK de release:

```bash
fvm flutter build apk --release
```

Arquivo gerado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 👨‍💻 Autor

Desenvolvido por **Douglas Antonio**.

Projeto desenvolvido para estudo, evolução profissional e portfólio.

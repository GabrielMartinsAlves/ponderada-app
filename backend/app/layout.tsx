import type { ReactNode } from 'react';

export const metadata = {
  title: 'Lumma Agendamentos — Backend',
  description: 'API de booking do Espaço Lumma',
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}

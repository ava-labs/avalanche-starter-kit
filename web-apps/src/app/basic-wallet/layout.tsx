import "@rainbow-me/rainbowkit/styles.css";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "../globals.css";
import  Providers from "./providers";
const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Glacier Basic Wallet",
  description: "Learn more about the Glacier SDK and API by AvaCloud",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
      <Providers>
      {children}
      </Providers>
  );
}

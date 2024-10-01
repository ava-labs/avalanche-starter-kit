import { ReactNode, MouseEventHandler } from 'react';

interface ButtonProps {
  children: ReactNode;
  onClick: MouseEventHandler<HTMLButtonElement>;
  className?: string;
}

export const Button = ({ children, onClick, className = '' }: ButtonProps) => (
    <button
      onClick={onClick}
      className={`px-4 py-2 bg-white/20 hover:bg-white/30 rounded transition-colors duration-200 ${className}`}
    >
      {children}
    </button>
  )
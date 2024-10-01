import { ReactNode } from 'react';

interface CardProps {
  title: string;
  children: ReactNode;
  className?: string;
}

export const Card = ({ title, children, className = '' }: CardProps) => (
    <div className={`bg-white/10 backdrop-blur-md border border-white/20 rounded-lg overflow-hidden shadow-lg ${className}`}>
      <div className="p-4 border-b border-white/20">
        <h2 className="text-xl font-semibold">{title}</h2>
      </div>
      <div className="p-4">
        {children}
      </div>
    </div>
  )
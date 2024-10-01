
import React, { ChangeEvent } from 'react';

interface InputProps {
  value: string;
  onChange: (event: ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  className?: string;
}

export const Input: React.FC<InputProps> = ({ value, onChange, placeholder, className = '' }) => (
    <input
      type="text"
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      className={`p-2 bg-white/10 border border-white/20 rounded text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-white/50 transition-all duration-200 ${className}`}
    />
  )
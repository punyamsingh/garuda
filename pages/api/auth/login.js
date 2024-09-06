// auth/login.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { email,password } = req.body;

        const { user,error } = await supabase.auth.signIn({
            email,
            password,
        });

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Login successful',user });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}

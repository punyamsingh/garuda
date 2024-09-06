// auth/logout.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { error } = await supabase.auth.signOut();

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Logout successful' });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}

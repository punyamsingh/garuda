// /api/offices/createOffice.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { office_name,office_latitude,office_longitude } = req.body;

        if (!office_name || !office_latitude || !office_longitude) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        try {

            const { data,error } = await supabase
                .from('offices')
                .insert([
                    {
                        office_name,
                        office_latitude,
                        office_longitude,
                    },
                ])
                .select()


            if (error) {
                return res.status(500).json({ error: error.message });
            }

            res.status(200).json({
                message: 'Office created successfully',
                office: data,
            });
        } catch (error) {
            res.status(500).json({ error: 'Failed to create office' });
        }
    } else {
        res.status(405).json({ error: 'Method not allowed' });
    }
}

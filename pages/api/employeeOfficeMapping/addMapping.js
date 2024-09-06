// employeeOfficeMapping/addMapping.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { employee_id,office_id } = req.body;

        // Insert a new mapping
        const { data,error } = await supabase
            .from('employee_office_mapping')
            .insert([{ employee_id,office_id }]);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Mapping added successfully',data });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}

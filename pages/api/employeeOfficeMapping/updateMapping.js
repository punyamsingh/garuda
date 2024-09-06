// employeeOfficeMapping/updateMapping.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'PUT') {
        const { employee_id,office_id } = req.body;

        // Update the mapping
        const { data,error } = await supabase
            .from('employee_office_mapping')
            .update({ office_id })
            .eq('employee_id',employee_id);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Mapping updated successfully',data });
    } else {
        res.setHeader('Allow',['PUT']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
